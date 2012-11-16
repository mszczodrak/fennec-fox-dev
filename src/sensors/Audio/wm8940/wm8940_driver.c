/*
 *   Copyright (c) 2010 University of São Paulo. All rights reserved.
 *   This file may be distributed under the terms of the GNU General
 *   Public License, version 3.
 *
 *   description: Robbie Adler's wm8940 mono codec driver adaptation
 *                (ported from TinyOS-1.x to TinyOS-2.x)
 *
 *   operating system: TinyOS-2.x
 *
 *   author: Thomas Cegal Gouthier de Vilhena <thomasvilhena@hotmail.com>
 *
 *   --------------------------------------------------------------------
 *   USAGE:
 *
 *   1) First, it is necessary to include "wm8940_driver.c" to your
 *      TinyOS-2.x application.
 *   2) Then, you must call the WmInitialize() function.
 *   3) Finally, call the WmWriteSample() function to play some music.
 *   4) Or call the WmReadSample() function to record some music.
 *
 *   --------------------------------------------------------------------
 *   ADDITIONAL INFORMATION:
 *
 *   1) Don't worry about any I2C or I2S stuff, because the WmInitialize()
 *      function already does that for you.
 *   2) The default sample rate is 8 kHz.
 *   3) At initialization, the loudspeaker volume is set to the highest
 *      value.
 *
 *   ---------------------------------------------------------------------
 */

#include<pxa27x_registers.h>
#include"WM8940.h"
    
/* wm8940 codec I2C address */
#define WM_I2CADDR    (0x1A)
    
/* wm8940 codec pinout */
#define WM_I2C_SCL     (117)
#define WM_I2C_SDA     (118)
#define WM_I2S_SYSCLK  (113)
#define WM_I2S_SYNC     (31)
#define WM_I2S_BITCLK   (28)
#define WM_I2S_DATAIN   (29)
#define WM_I2S_DATAOUT  (30)
    
    /*-------------------------------------- pxa271 I2C Functions -------------------------------------*/
    
    /* I2C GPIO configuration */
    void I2cConfigPins()
    {
        _GPIO_setaltfn(WM_I2C_SCL,1);            /* output */
        GPDR(WM_I2C_SCL)|=_GPIO_bit(WM_I2C_SCL);
        _GPIO_setaltfn(WM_I2C_SDA,1);            /* output */
        GPDR(WM_I2C_SDA)|=_GPIO_bit(WM_I2C_SDA);
    }
    
    /* enables I2C clocks */
    void I2cConfigReg()
    {
        CKEN |= (1<<14);
        CKEN |= (1<<15);
    }
    
    /* enables I2C */
    void I2cEnable()
    {
        ICR |= ICR_IUE;
        ICR |= ICR_SCLE;
    }
    
    /* disables I2C */
    void I2cDisable()
    {
        ICR &= ~(ICR_IUE);
        ICR &= ~(ICR_SCLE);
    }
    
    /* I2C write transaction */
    void I2cWriteRegister( uint8_t devAddr, uint8_t regAddr, uint16_t data )
    {
        IDBR = (devAddr<<1);                /* device address */
        ICR |= ICR_START;
        ICR &= ~(ICR_STOP); 
        ICR |= ICR_TB;
        while( (ICR&(1<<3))!=0 );
        
        IDBR = regAddr;                     /* register address */
        ICR &= ~(ICR_START);
        ICR &= ~(ICR_STOP); 
        ICR |= ICR_TB;
        while( (ICR&(1<<3))!=0 );
        
        IDBR = (data>>8);                   /* first data byte */
        ICR &= ~(ICR_START);
        ICR &= ~(ICR_STOP); 
        ICR |= ICR_TB;
        while( (ICR&(1<<3))!=0 );
        
        IDBR = (data&0xFF);                 /* second data byte */
        ICR &= ~(ICR_START);
        ICR |= ICR_STOP; 
        ICR |= ICR_TB;
        while( (ICR&(1<<3))!=0 );
        ICR &= ~(ICR_STOP);
    }
    
    /* I2C read transaction */
    uint16_t I2cReadRegister( uint8_t devAddr, uint8_t regAddr )
    {
        uint16_t data;
        
        IDBR = (devAddr<<1);                /* device address */
        ICR |=   ICR_START;
        ICR &= ~(ICR_STOP); 
        ICR |=   ICR_TB;
        while( (ICR&(1<<3))!=0 );
                
        IDBR = regAddr;                     /* register address */
        ICR &= ~(ICR_START);
        ICR &= ~(ICR_STOP); 
        ICR |= ICR_TB;
        while( (ICR&(1<<3))!=0 );
        
        IDBR = (devAddr<<1)|1;              /* device address */
        ICR |=   ICR_START;
        ICR &= ~(ICR_STOP); 
        ICR |=   ICR_TB;
        while( (ICR&(1<<3))!=0 );
        
        ICR &= ~(ICR_START);
        ICR &= ~(ICR_STOP);
        ICR |=   ICR_TB;
        while( (ICR&(1<<3))!=0 );
        data = (IDBR<<8);                   /* first data byte */
        
        ICR &= ~(ICR_START);
        ICR |= ICR_STOP;
        ICR |= ICR_ACKNAK;
        ICR |= ICR_TB;
        while( (ICR&(1<<3))!=0 );
        data |= IDBR&0xFF;                  /* second data byte */
        
        ICR &= ~(ICR_STOP);
        ICR &= ~(ICR_ACKNAK);
        
        return data;
    }
    
    /*-------------------------------------- pxa271 I2S Functions -------------------------------------*/

    /* I2S GPIO configuration */
    void I2sConfigPins()
    {
        _GPIO_setaltfn(WM_I2S_BITCLK,1);                /* output */
        GPDR(WM_I2S_BITCLK)|=_GPIO_bit(WM_I2S_BITCLK);
        _GPIO_setaltfn(WM_I2S_SYSCLK,1);                /* output */
        GPDR(WM_I2S_SYSCLK)|=_GPIO_bit(WM_I2S_SYSCLK);
        _GPIO_setaltfn(WM_I2S_SYNC,1);                  /* output */
        GPDR(WM_I2S_SYNC)|=_GPIO_bit(WM_I2S_SYNC);
        _GPIO_setaltfn(WM_I2S_DATAOUT,1);               /* output */
        GPDR(WM_I2S_DATAOUT)|=_GPIO_bit(WM_I2S_DATAOUT);
        _GPIO_setaltfn(WM_I2S_DATAIN,2);                /* input */
        GPDR(WM_I2S_DATAIN)&=~_GPIO_bit(WM_I2S_DATAIN);
    }
  
    /* I2S interface configuration */
    void I2sConfigReg()
    {
        CKEN |= (1<<8);
        SACR0 |= (1<<3);
        SACR0 &= ~(1<<3);
        SACR0 |= (1<<2);
    }
    
    /* sample rate selection */
    void I2sSetSamplingRate( uint8_t kHz )
    {
        switch( kHz )
        {
            case 8:
                SADIV = 0x48;   /* 8.00 kHz */
                break;
            case 11:
                SADIV = 0x34;   /* 11.025 kHz */
                break;
            case 16:
                SADIV = 0x24;   /* 16.00 kHz */
                break;
            case 22:
                SADIV = 0x1A;   /* 22.05 kHz */
                break;
            case 44:
                SADIV = 0x0D;   /* 44.1 kHz */
                break;
            default:
                SADIV = 0x0C;   /* 88 kHz */
                break;
        }
    }
    
    /* enables I2S */
    void I2sEnable()
    {
        SACR0 |= (1<<0);
    }
    
    /* disables I2S */
    void I2sDisable()
    {
        SACR0 &= ~(1<<0);
    }
    
    /*--------------------------------------  WM8940 Functions  ---------------------------------------*/
    
    /* writes data to wm8940 register */
    void WmWriteRegister( uint8_t regAddr, uint16_t data )
    {
        I2cWriteRegister( WM_I2CADDR, regAddr, data );
    }
    
    /* reads data from wm8940 registers (according to the data sheet, only RO and R1 registers can be read) */
    uint16_t WmReadRegister( uint8_t regAddr )
    {
        return I2cReadRegister( WM_I2CADDR, regAddr );
    }
    
    /* codec intialization */
    void WmInitialize()
    {
        /* I2C initialization */
        I2cConfigPins();
        I2cConfigReg();
        I2cEnable();
        /* initialization sequence described on page 64 of wm8940 data sheet */
        WmWriteRegister( SOFTWARERESET, 0 );
        WmWriteRegister( POWERMANAGEMENT1, POWERMANAGEMENT1_VMID_OP_EN|POWERMANAGEMENT1_LVLSHIFT_EN );
        WmWriteRegister( DACCONTROL, DACCONTROL_DACMU );
        WmWriteRegister( CLOCKGENCONTROL, CLOCKGENCONTROL_MCLKDIV(0)|CLOCKGENCONTROL_BCLKDIV(0) );
        WmWriteRegister( ADDITIONALCONTROL, ADDITIONALCONTROL_POB_CTRL|ADDITIONALCONTROL_SOFT_START|ADDITIONALCONTROL_SR(5) );
        WmWriteRegister( POWERMANAGEMENT3, POWERMANAGEMENT3_SPKPEN|POWERMANAGEMENT3_SPKNEN );
        WmWriteRegister( POWERMANAGEMENT1, POWERMANAGEMENT1_VMID_OP_EN|POWERMANAGEMENT1_LVLSHIFT_EN|POWERMANAGEMENT1_VMIDSEL(1) );
        WmWriteRegister( POWERMANAGEMENT1, POWERMANAGEMENT1_VMID_OP_EN|POWERMANAGEMENT1_LVLSHIFT_EN|POWERMANAGEMENT1_VMIDSEL(1)|POWERMANAGEMENT1_BIASEN|POWERMANAGEMENT1_BUFIOEN|POWERMANAGEMENT1_MICBEN );
        WmWriteRegister( ADDITIONALCONTROL, ADDITIONALCONTROL_SR(5) ); /* sample rate set to 8 khz (must match I2S sample rate) */
        WmWriteRegister( POWERMANAGEMENT3, POWERMANAGEMENT3_SPKPEN|POWERMANAGEMENT3_SPKNEN|POWERMANAGEMENT3_DACEN|POWERMANAGEMENT3_SPKMIXEN );
        WmWriteRegister( SPKMIXERCONTROL, SPKMIXERCONTROL_DAC2SPK );
        WmWriteRegister( SPKVOLUMECONTROL, 0 );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((-27)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((-25)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((-13)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((-11)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((-9)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((-8)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((-7)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((-6)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((-5)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((-4)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((-3)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((-2)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((-1)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((0)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((1)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((2)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((3)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((4)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((5)-(-57)) );
        WmWriteRegister( SPKVOLUMECONTROL, SPKVOLUMECONTROL_SPKVOL((6)-(-57)) );
        WmWriteRegister( DACCONTROL, 0 );
        WmWriteRegister( AUDIOINTERFACE, AUDIOINTERFACE_LOUTR|AUDIOINTERFACE_WL(0)|AUDIOINTERFACE_FMT(2) );
        WmWriteRegister( INPUTCTRL, INPUTCTRL_MICN2INPPGA|INPUTCTRL_MICP2INPPGA );
        WmWriteRegister( POWERMANAGEMENT2, POWERMANAGEMENT2_INPPGAEN|POWERMANAGEMENT2_ADCEN|POWERMANAGEMENT2_BOOSTEN );
        WmWriteRegister( INPPGAGAINCTRL, INPPGAGAINCTRL_INPPGAZC|INPPGAGAINCTRL_INPPGAVOL(0x3F) );
        WmWriteRegister( ADCDIGITALVOLUME, 0xFF );
        /* I2S initialization */
        I2sConfigPins();
        I2sConfigReg();
        I2sSetSamplingRate(8);
        I2sEnable();
    }
    
    /* codec volume adjust (min = 0, max = 255) */
    void WmSetVolume( uint8_t volume )
    {
        WmWriteRegister( DACDIGITALVOLUME, DACDIGITALVOLUME_DACVOL(volume));
    }
    
    /* writes one audio sample to the I2S TXFIFO buffer */
    void WmWriteSample( uint16_t sample )
    {
        while( (SASR0&1)==0 );
        SADR = (sample<<16)|(sample&0xFFFF);
    }
    
    /* reads one audio sample from the I2S RXFIFO buffer */
    uint16_t WmReadSample()
    {
        while( (SASR0&2)==0 );
        return (SADR)&0xFFFF;
    }
