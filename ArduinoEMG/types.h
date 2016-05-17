enum TriggerType{
  RISING_EDGE,
  FALLING_EDGE,
  ABOVE_THRESH,
  BELOW_THRESH
};

String ttToString(TriggerType t){
  if(t == TriggerType::RISING_EDGE)
    return "RISING";
  if(t == TriggerType::FALLING_EDGE)
    return "FALLING";
  if(t == TriggerType::ABOVE_THRESH)
    return "ABOVE";
  if(t == TriggerType::BELOW_THRESH)
    return "BELOW";
  return "";
}

int ttToInt(TriggerType t){
  if(t == TriggerType::RISING_EDGE)
    return 0;
  if(t == TriggerType::FALLING_EDGE)
    return 1;
  if(t == TriggerType::ABOVE_THRESH)
    return 2;
  if(t == TriggerType::BELOW_THRESH)
    return 3;
  return -1;
}
