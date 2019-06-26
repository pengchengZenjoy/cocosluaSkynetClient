protoc --descriptor_set_out  C2SMsg.pb C2SMsg.proto
protoc --descriptor_set_out  S2CMsg.pb S2CMsg.proto
cp C2SMsg.pb ../res/
cp S2CMsg.pb ../res/
cp C2SMsg.pb ../../../mySkynetServer/protos
cp S2CMsg.pb ../../../mySkynetServer/protos