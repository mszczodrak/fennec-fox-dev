configuration WM8940C {
  provides interface Audio;
}

implementation {

  components WM8940P;
  Audio = WM8940P;

}
