//Version 1.0

/** The interface to UWB radio driver.
  *
  * @author Jianxun Zhu
  * @date   March 11 2011
  */ 

#include <TinyError.h>

interface EnhantsPHY
{

	/**
	* Initialize the hardware configuration, including pin direction setup,
	* timer and comparator configuration setup, external interrupt setup.
	* Must be invoked before any other commands.
	*
	*/
	command void init();


	/**
	* Set communication direction to sending. Switch the RF switch to the 
	* transmitter side. Disable receiver interrupt.
	*
	* @return	SUCCESS if direction change succeeded. 
	*		(Currently always return SUCCESS)
	*		
	*
	*/
	async command error_t set_direction_send();


	/**
	* Set communication direction to receiving. Switch the RF switch to the 
	* receiver side. Enable receiver interrupt.
	*
	* @return	SUCCESS if direction change succeeded;
	*		FAIL if a sending action is still in progress.
	*
	*/	
	async command error_t set_direction_recv();


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
	async command error_t phy_send(uint8_t *msg, uint32_t length);

	/**
	* Signaled when all the bytes in sending buffer are sent.
	*
	* @see phy_send
	*/
	event void phy_send_complete();


	/**
	* Signaled when the number of data in the receive buff reaches 
	* integer times of "recv_batch_size". The received data can then 
	* be obtained using command extract.
	* See command set_batch_size, extract
	*
	* @see set_batch_size
	* @see extract
	*/
  event void data_arrived(msg_t *new_msg);
}


