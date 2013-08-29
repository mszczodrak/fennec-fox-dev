configuration EHC {
provides interface SplitControl;

}
implementation {
components EHP;
SplitControl = EHP;

components new TimerMilliC();

EHP.Timer -> TimerMilliC;


}
