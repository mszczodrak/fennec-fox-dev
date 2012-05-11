//Version 1.0

/** The module of UWB radio driver.
  *
  * @author Jianxun Zhu
  * @date   March 11 2011
  */ 

#include <Atm128Timer.h>
#include <TinyError.h>
#include <crc.h>
#include "Timer.h"
#include <Fennec.h>

#ifdef _ESENDBYTE_APP_H
  #define PACKET_LEN_MIN 6
#else
  #define PACKET_LEN_MIN 10
#endif

#define PACKET_LEN_MAX 25
#define PACKET_LEN_FIELD 2
#define PACKET_DEST_FIELD 2
#define PREAMBLE_LENGTH 2

module HplUWBCISL01P @safe() {

  provides interface Module;
  provides interface EnhantsPHY;
	
  uses interface HplAtm128Compare<uint16_t> as CompareA;
  uses interface HplAtm128TimerCtrl16 as TimerCtrl;

  uses interface GeneralIO as PinClk1;		//timer output (clk1)
  uses interface GeneralIO as PinTxData;	//data output (tx_data)
  uses interface GeneralIO as PinRfSwitch;	//RF switch ctrl (0:RX 1:TX)

  uses interface GeneralIO as PinC0;	//pins for mote_data[0:7]
  uses interface GeneralIO as PinC1;
  uses interface GeneralIO as PinC2;
  uses interface GeneralIO as PinC3;
  uses interface GeneralIO as PinC4;
  uses interface GeneralIO as PinC5;
  uses interface GeneralIO as PinC6;
  uses interface GeneralIO as PinC7;

  uses interface HplAtm128Interrupt as Int0;	//interrupt for clock input (mote_clock)
  uses interface HplAtm128Interrupt as Int1;	//interrupt for preamble detection

  uses interface GeneralIO as PinF2;

  uses interface Crc;
}

implementation
{
  Atm128TimerCtrlCompare_t compare;
  Atm128TimerCtrlCapture_t capture;


  uint8_t* send_buff; //pointer for send buffer, provided by parameter of 'phy_send'
  uint32_t send_buff_length;  //send buffer legal length.
  uint32_t send_buff_index;	//index of the next byte to be transmitted.
  uint8_t send_byte_mask; //bit mask for the intended bit to be transmitted in a byte,
	                //note that this bit mask changes from 0x80 to 0x01, sending MSB before LSB
  uint8_t send_complete = 0;//flag for sending operation, '0' means "in progress", '1' means "finished"
  uint8_t received_byte = 0;

  uint8_t send_buffer_preamble[2] = {8, 229};
  bool send_preamble = TRUE;

  task void task_phy_send_complete();
  task void task_send_bit();
  task void task_signal_received();
  void set_direction_recv();

  norace msg_t *message = NULL;
  norace uint8_t incomming_length = 0;

  // after we received the packet we can disable the preemble and mote clock interrupt to receive more bytes, because we signal the received data to the higher layer
  void disable_all_irq()
  {
    call Int1.clear();
    call Int1.disable();
    call Int0.clear();
    call Int0.disable();
  }

// if we receive a packet not addressed for us we disable the mote clock interrupt and wait for receiving the next preemble interrupt
	void disable_mote_clock_irq()
	{
  	call Int0.clear();
    call Int0.disable();
	}

	// after the signaling of the received data to the higher layer is done we enable the preemble interrupt
  void enable_preemble_irq()
  {
		//call PinF1.set();

		call Int1.clear();
		call Int1.enable();
  }

  // preamble detected interrupt
  async event void Int1.fired() 
  {
    atomic
    {
			message->len = 0;
			incomming_length = 0;

      call Int0.clear();
      call Int0.enable();
    }
  }

	// interrupt routine for mote_clock, which indicates a new byte has arrived.
	async event void Int0.fired() 
	{
		//call PinF0.toggle();

    atomic 
    {
      message->data[incomming_length] = PINC;
      incomming_length++;

      if(incomming_length == PACKET_LEN_FIELD)
      {
        memcpy(&message->len, message->data + sizeof(uint8_t), sizeof(uint8_t));
       
        // to keep save in case if the len byte is corrupted
        if(message->len < PACKET_LEN_MIN || message->len > PACKET_LEN_MAX)
        {
          message->len = PACKET_LEN_MIN;
        }
      }
      
      if(incomming_length > PACKET_LEN_FIELD) 
      {
        if(incomming_length == message->len) 
        {
					if(TOS_NODE_ID == message->data[PACKET_DEST_FIELD] || message->data[PACKET_DEST_FIELD] == 0 || message->data[PACKET_DEST_FIELD] == 99)
					{
          	disable_all_irq();
         	  post task_signal_received();
					}
					else
					{
						//packet_errors = packet_errors + 1;
				
						disable_mote_clock_irq();

						message->len = 0;
						incomming_length = 0;
					}
        }
      }
    }
	}

  task void task_signal_received()
  {
    msg_t *new_msg = message;
    atomic
    {
      message = signal Module.next_message();
      message->len = 0;
      incomming_length = 0;
    }
    signal EnhantsPHY.data_arrived(new_msg);
    enable_preemble_irq();
  }

	//event void Timer.fired() {}		//Implemented due to tinyOS syntax, don't handle this event.

  task void task_send_bit() {}

	async event void CompareA.fired() // rising edge at clock 1 because compareA value == timer1 value
	{
    atomic 
    {
      if (!call PinClk1.get())
		  {
        if(!send_complete) 
        { 
			    // if the bit selected by "send_byte_mask" is '1', then set tx_data to '1'
          if(send_preamble == TRUE)
          {
            if(send_buffer_preamble[send_buff_index] & send_byte_mask)	
			      {
				      call PinTxData.set();
			      }
			      else
			      {
				      call PinTxData.clr();
			      }    
          }       
          else
          {			    
            if(send_buff[send_buff_index-PREAMBLE_LENGTH] & send_byte_mask)	// -2 because send_buff_index is 2 after we sent the preamble
			      {
				      call PinTxData.set();
			      }
			      else
			      {
				      call PinTxData.clr();
			      }
	        }
			  
          send_byte_mask = send_byte_mask >> 1; //shift to next bit in the current byte.

          if ((send_byte_mask & 0xff) == 0x00)	
	        {
		        send_byte_mask = 0x80; 	//reset the mask to MSB if the 8 bits in the current byte are all sent.
		        send_buff_index ++;	    //shift to next byte.

            if(send_preamble == TRUE && send_buff_index == PREAMBLE_LENGTH)
            {
              send_preamble = FALSE;    
            } 
	        }
        }

		    if (send_buff_index == send_buff_length)
		    {
          if(send_complete == 1)
          {
            atomic 
            {
              call CompareA.stop();		//Stop compare A interrupt

			        compare.bits.comA = 1;		//OC3A toggle on compare match
			        capture.bits.wgm32 = 1;		//CTC mode
			        capture.bits.cs = 0;		  //prescaler

			        //set the control bits for the compare
			        call TimerCtrl.setCtrlCompare(compare);
			        call TimerCtrl.setCtrlCapture(capture);
              //TCCR3B = 0x0000; // Counter3 stop
            }

            //TCCR3B = 0x0000; // Counter3 stop

            send_complete = 0;
            set_direction_recv();
            post task_phy_send_complete();
          }
          else
          { 
            send_complete = 1;
          }
			  }
		  }
    }
  }

  task void task_phy_send_complete()
  {
    signal EnhantsPHY.phy_send_complete();
  }

//*****************Implementation for interface EnhantsPHY*****************************

  /**
   * Initialize the hardware configuration, including pin direction setup,
   * timer and comparator configuration setup, external interrupt setup.
   * Must be invoked before any other commands.
   *
   */
  command void EnhantsPHY.init() {

    message = signal Module.next_message();
    message->len = 0;
    incomming_length = 0;

    //Make input pins
    call PinC0.makeInput();
    call PinC1.makeInput();
    call PinC2.makeInput(); 
    call PinC3.makeInput(); 
    call PinC4.makeInput(); 
    call PinC5.makeInput(); 
    call PinC6.makeInput(); 
    call PinC7.makeInput();
    call PinF2.makeInput();

    //Make output pins
    call PinTxData.makeOutput();
    call PinRfSwitch.makeOutput();
    call PinClk1.makeOutput();

    call PinTxData.clr();
    call PinRfSwitch.clr();
    call PinClk1.clr();

    //compare control //////////////to be refactored into data rate control function
    call CompareA.set(200);//170);//170);//170);//170);//500);//(300);//190); //500
		
    //initialize receiving interrupt
    call Int0.clear();
    call Int0.edge(TRUE);
    call Int0.disable();

    //initialize preamble interrupt
    call Int1.clear();
    call Int1.edge(TRUE);
    call Int1.enable();
  }

	/**
	* Set communication direction to sending. Switch the RF switch to the 
	* transmitter side. Disable receiver interrupt.
	*
	* @return	SUCCESS if direction change succeeded. 
	*		(Currently always return SUCCESS)
	*
	*/
	async command error_t EnhantsPHY.set_direction_send() 
	{
    if(!call PinF2.get()) // if PinF2 == 0, we are allowed to send, channel is free
    {
      call PinRfSwitch.set();

      call Int0.clear();
      call Int0.disable();
      call Int1.clear();
      call Int1.disable();
			
			//call PinF1.clr();

      return SUCCESS;
    }
    return FAIL;
	}

	/**
	* Set communication direction to receiving. Switch the RF switch to the 
	* receiver side. Enable receiver interrupt.
	*
	* @return	SUCCESS if direction change succeeded;
	*		FAIL if a sending action is still in progress.
	*
	*/	
	async command error_t EnhantsPHY.set_direction_recv() 
	{
    call PinRfSwitch.clr();

    call Int1.clear();
		call Int1.enable();

		//call PinF1.set();

    call Int0.clear();
		call Int0.disable();

		return SUCCESS;
	}

	/**
	* Set communication direction to receiving. Switch the RF switch to the 
	* receiver side. Enable receiver interrupt.
	*
	*/
  void set_direction_recv() 
  {
    call PinRfSwitch.clr();

    call Int1.clear();
		call Int1.enable();

		//call PinF1.set();

    call Int0.clear();
		call Int0.disable();
  }

	/**
	* Send a sequence of bytes by the transmitter. The effective bytes in
	* the array start from index 0 and last for 'length' bytes. 
	* The highest bit (MSB) of a byte is sent first, and the lowest bit (LSB)
	* is sent last. An event 'send_complete' will be signaled when the sending
	* has completed. This command is not reentriable. EBUSY is returned if a 
	* previous sending has not finished.
	*
	* @return	SUCCESS if direction change succeeded;
	*		EBUSY if the previous sending action is still in progress;
	*		FAIL if the radio is in receive mode.
	*
	* @param	'uint8_t* ONE msg'   	the message to be sent.
	* @param	'uint32_t length'      	the length of the message.	
	*
	* @see		send_complete
	*
	*/
	async command error_t EnhantsPHY.phy_send(uint8_t *msg, uint32_t length) 
	{
    uint16_t crc = 0;

		atomic
		{
			send_complete = 0;	//set complete flag to 0 (sending not completed).
			send_buff = msg;
      
			send_buff_length = length+2; // + 2 preamble bytes at the beginning
      send_buff_length += 2; // + 2 checksum bytes at the end
      //send_buff_length += 1; // 1 additional zero at the end, just to play safe
  
      send_buff[1] = length+2; // the len in the header is smaller by -1 than length, we set the len in the header to length+2 because we include the checksum

	    send_buff_index = 0;
      send_preamble = TRUE;
			send_byte_mask = 0x80;

      crc = call Crc.crc16(&send_buff[0],length);
      send_buff[length] = (crc & 0x00FF); // LSB
      send_buff[length+1] = (crc & 0xFF00) >> 8; // MSB
    }

		TCNT3 = 0x0000; // Counter3 clear

		atomic
		{
			compare.bits.comA = 1;		//OC3A toggle on compare match
			//compare.bits.wgm10 = 1;
			//capture.bits.wgm32 = 0;//1;		//CTC mode
      capture.bits.wgm32 = 1;		//CTC mode
			capture.bits.cs = 1;		//prescaler

			//set the control bits for the compare
			call TimerCtrl.setCtrlCompare(compare);
			call TimerCtrl.setCtrlCapture(capture);
		}

		call CompareA.start();		//start to accept compare interrupt.

		return SUCCESS;
	}
}
