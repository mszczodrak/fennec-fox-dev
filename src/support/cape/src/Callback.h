#ifndef CALLBACK_H
#define CALLBACK_H

class Mote;

class Callback
{
   public:
      Callback(){}

      virtual ~Callback(){}
      virtual void call(Mote& object){} 
};

#endif
