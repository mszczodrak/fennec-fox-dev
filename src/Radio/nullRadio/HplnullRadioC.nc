configuration HplnullRadioC {
        provides {
                interface LocalTime<TRadio> as LocalTimeRadio;
                interface Init;
                interface Alarm<TRadio,uint16_t>;
        }
}
implementation {


        components new AlarmMicro16C() as AlarmC;
        Alarm = AlarmC;
        Init = AlarmC;

        components LocalTimeMicroC;
        LocalTimeRadio = LocalTimeMicroC.LocalTime;
}

