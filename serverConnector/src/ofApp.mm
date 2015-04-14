#include "ofApp.h"


//--------------------------------------------------------------
void ofApp::setup(){	
    ofxLibwebsockets::ServerOptions options = ofxLibwebsockets::defaultServerOptions();
    options.port = 9092;
    options.bUseSSL = false; // you'll have to manually accept this self-signed cert if 'true'!
    bSetup = server.setup( options );
    server.addListener(this);
    
    ofSetFrameRate(12);
    initStructures();
    //iPhone 1
    NSArray *whiteList = @[@"AB316079-B6D3-89EA-5C09-080DAA732412",@"E8DA9D39-D32D-CF43-E712-FEDCA7ECA7AE",@"F427F60B-339F-8BDF-30D8-C236D02938BE",@"F427F60B-339F-8BDF-30D8-C236D02938BE",@"5411D6D5-D52F-8E34-D574-2A37CC97F088"];
   
    //iPhone 2
    // NSArray *whiteList = @[@"A8F6BEC0-4EB0-DDED-6EF8-29348E410AD5",@"28B7A6AA-17F3-8610-654E-4FFB29FEF53F",@"29EBC459-2783-1E5D-DADA-9F82D7C67A4F",@"C9D75924-F179-60DF-45FA-E71B7E0AD385",@"10F3E10D-B6A9-B941-F69F-C03152EEBEE2"];
    
    //iPod Touch
    //iPod Touch NSArray *whiteList = @[@"D91E5D1A-FC24-378C-7B58-AD466B1CFB2E",@"2A4C3C59-F907-6139-D5F9-68000C530341",@"D407D25F-6787-DA30-712C-ED9D5807ED24",@"B75BECC7-62D4-0813-5A1B-A846FA439499",@"43F9E234-6D1D-0557-4BFF-51105371ECEC"];
    
    for(int i = 0; i<[whiteList count]; i++)
    {
        idNumberReference[[[whiteList objectAtIndex:i ] UTF8String]]=i;
    }
    // Begin scanning for MetaWear boards
    [[MBLMetaWearManager sharedManager] startScanForMetaWearsWithHandler:^(NSArray *array) {
        // Hooray! We found a MetaWear board
        // Connect to the board we found
        for (int i=0; i<[array count]; i++) {
            MBLMetaWear *device = [array objectAtIndex:i];
            
            
           if([whiteList indexOfObject:device.identifier.UUIDString]!= NSNotFound)
            {
                [device connectWithHandler:^(NSError *error) {
                    if (!error) {
                        
                        // Hooray! We connected to a MetaWear board, so flash its LED!
                        [device.led flashLEDColor:[UIColor greenColor] withIntensity:1 numberOfFlashes:2];
                        //[device forgetDevice];
                       
                            bleDeviceMap[idNumberReference[device.identifier.UUIDString.UTF8String]]=device;
                            numOfConnectedDevices=0;
                            accessGranted[idNumberReference[device.identifier.UUIDString.UTF8String]] = false;
                        
                            device.accelerometer.sampleFrequency = MBLAccelerometerSampleFrequency1_56Hz;
                        
                        
                        
                            for (int k=0; k<MAX_NUM_OF_DEVICES; k++) {
                                if(bleDeviceMap[k]!=nil)
                                {
                                    numOfConnectedDevices++;
                                }
                            }

                       
                    }
                }];
              }
            else
            {
                NSLog(@"device %@",device.identifier.UUIDString);
            }
          
        }
    }];
    
   
}

//--------------------------------------------------------------
void ofApp::update(){
    sendAccelerometerData();
}

//--------------------------------------------------------------
void ofApp::draw(){
    
    ofBackground(0, 0, 0);
    if ( bSetup ){
        ofSetColor(0,150,0);
        
        ofDrawBitmapString("WebSocket server setup at "+ofToString( server.getPort() ) + ( server.usingSSL() ? " with SSL" : " without SSL"), 20, 20);
        
        ofSetColor(150);
    } else {
        ofDrawBitmapString("WebSocket setup failed :(", 20,20);
    }
    
    int x = 20;
    int y = 50;
    
    ofSetColor(255);
    for (int i = messages.size() -1; i >= 0; i-- ){
        ofDrawBitmapString( messages[i], x, y );
        y += 20;
    }
    if (messages.size() > NUM_MESSAGES) messages.erase( messages.begin() );
    
    
    ofSetColor(255,200);
    for (int i=0; i<MAX_NUM_OF_DEVICES; i++) {
        if(bleDeviceMap[i]!=NULL)
        {
            ofNoFill();
             ofSetLineWidth(1);
            ofRect(i*18+18, ofGetHeight()-15, 15, 15);
            ofFill();
        }
    }
    for(int i=0; i<MAX_NUM_OF_DEVICES; i++)
    {
       
        ofRect(i*18+18, ofGetHeight()-15, 8, 8);
        
    }
}

//--------------------------------------------------------------
void ofApp::exit(){
    //server.close();
}
//--------------------------------------------------------------
void ofApp::lostFocus(){
   // server.close();

}
//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){
    
}
//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){
    messages.clear();
    for (int i=0; i<MAX_NUM_OF_DEVICES; i++) {
        
    if(bleDeviceMap[i]!=NULL)
    {
        NSLog(@"started %@",bleDeviceMap[i].identifier);
        /*
        [bleDeviceMap[i].accelerometer.rmsDataReadyEvent startNotificationsWithHandler:^(id obj, NSError *error) {
           
             NSLog(@"device num %@,%@",bleDeviceMap[i].identifier, obj);
        }];*/
        bleDeviceMap[i].accelerometer.fullScaleRange = MBLAccelerometerRange8G;  // Default: +- 8G
        bleDeviceMap[i].accelerometer.sampleFrequency = MBLAccelerometerSampleFrequency100Hz;
        [bleDeviceMap[i].accelerometer.dataReadyEvent startNotificationsWithHandler:^(MBLAccelerometerData *acceleration, NSError *error) {
            accValues[i].x=(int)acceleration.x;
            accValues[i].y=(int)acceleration.y;
            accValues[i].z=(int)acceleration.z;
           
        }];
    }
    }
}
/****************
 ******
 WEBSOCKET METHODS
 ****************/
//--------------------------------------------------------------
void ofApp::onConnect( ofxLibwebsockets::Event& args ){
    cout<<"on connected"<<endl;
    
}

//--------------------------------------------------------------
void ofApp::onOpen( ofxLibwebsockets::Event& args ){
    cout<<"new connection open"<<endl;
    ofxLibwebsockets::Connection cTmp=args.conn;
    string sTmp=cTmp.getClientName();
 
    messages.push_back(ofToString(ofGetFrameNum())+" conn " + cTmp.getClientIP() );
    
    assignIPToDevice(cTmp.getClientIP());
   
}

//--------------------------------------------------------------
void ofApp::onClose( ofxLibwebsockets::Event& args ){
    cout<<"on close"<<endl;
    messages.push_back("Connection closed");
    retractIPToDevice(args.conn.getClientIP());
  
}

//--------------------------------------------------------------
void ofApp::onIdle( ofxLibwebsockets::Event& args ){
    //cout<<"on idle"<<endl;
    
}

//--------------------------------------------------------------
void ofApp::onMessage( ofxLibwebsockets::Event& args ){
    cout<<"got message "<<args.message<<endl;
   
    string from = args.conn.getClientIP();
    
    string message = args.json.get("message", "error").asString();
    messages.push_back("message: "+message);
    printf("%d mess %s %s",ofGetFrameNum(),from.c_str(),message.c_str());
    
    if(message=="setColor")
    {
        int deviceIndex = args.json.get("device", -1).asInt();
        int red         = args.json.get("red", -1).asInt();
        int green       = args.json.get("green", -1).asInt();
        int blue        = args.json.get("blue", -1).asInt();
        int intensity   = args.json.get("intensity", -1).asInt();
       
        if(deviceIndex<=MAX_NUM_OF_DEVICES && deviceIndex>=0 && deviceIndex<numOfConnectedDevices && red>=0 && red <256 && green>=0 && green <256 && blue>=0 && blue <256 && intensity>=0 && intensity <256)
        {
            
            
            [bleDeviceMap[deviceIndex].led setLEDColor:[UIColor colorWithRed:red green:green blue:blue alpha:255] withIntensity:ofMap(intensity, 0, 255, 0, 1)];
        }
        else
        {
            
            string errorMessage="{\"message\":\"error\",\"type\":\"Set Color failed :: incorrect index\"}";
            server.send(errorMessage, args.conn.getClientIP());
        }
        
        return;
    }
    else if(message == "registerButton")
    {
        int deviceIndex = args.json.get("device", -1).asInt();
        string ipAddress = args.conn.getClientIP();
        
        if(deviceIndex<=MAX_NUM_OF_DEVICES && deviceIndex>=0 && deviceIndex<numOfConnectedDevices)
        {
            if(registeredForButton.find(deviceIndex)==registeredForButton.end())
            {
                bool ipPresent = false;
                for (std::map<int, string>::iterator it=registeredForButton.begin(); it!=registeredForButton.end(); it++) {
                    string ipTmp=it->second;
                    if(ipTmp==ipAddress)
                    {
                        ipPresent=true;
                    }
                }
                if(!ipPresent){
                    [bleDeviceMap[deviceIndex].mechanicalSwitch.switchUpdateEvent startNotificationsWithHandler:^(MBLNumericData* obj, NSError   *error) {
                        string newMessage="{\"message\":\"buttonEvent\",\"value\":\""+ofToString([obj.value integerValue])+"\"}";
                        server.send(newMessage, ipAddress);
                    }];
                    registeredForButton[deviceIndex]=ipAddress;
                }
                else
                {
                    string errorMessage="{\"message\":\"error\",\"type\":\"Register for button failed :: ip address already registered for this event\"}";
                    server.send(errorMessage, ipAddress);
                }
            }
        }
        else
        {
            string errorMessage="{\"message\":\"error\",\"type\":\"Register for button failed :: incorrect index\"}";
            server.send(errorMessage, ipAddress);
        }
        
        return;
    }
    else if(message == "releaseButton")
    {
        int deviceIndex = args.json.get("device", -1).asInt();
        string ipAddress = args.conn.getClientIP();
        
        
        
        for (std::map<int, string>::iterator it=registeredForButton.begin(); it!=registeredForButton.end(); it++) {
            string ipTmp=it->second;
            if(ipTmp==ipAddress)
            {
                [bleDeviceMap[it->first].mechanicalSwitch.switchUpdateEvent stopNotifications];
                registeredForButton.erase(deviceIndex);
                break;
            }
        }
    }
    else if(message == "registerAccelerometer")
    {
        int deviceIndex = args.json.get("device", -1).asInt();
        string ipAddress = args.conn.getClientIP();
        
        
        if(deviceIndex<=MAX_NUM_OF_DEVICES && deviceIndex>=0 && deviceIndex<numOfConnectedDevices)
        {
            if(ipAddress == bleIPMap[deviceIndex] || accessGranted[deviceIndex])
            {
                vector<string> *vTmp=&registeredForAccelerometer[deviceIndex];
                
                if(std::find(vTmp[deviceIndex].begin(), vTmp[deviceIndex].end(),ipAddress) == vTmp[deviceIndex].end() )
                {
                    vTmp->push_back(ipAddress);
                }
                else
                {
                    string errorMessage="{\"message\":\"error\",\"type\":\"Register for accelerometer failed :: ip address already registered for this event\"}";
                    server.send(errorMessage, ipAddress);
                }
            }
            else
            {
                string errorMessage="{\"message\":\"error\",\"type\":\"Register for accelerometer failed :: the device you are trying to read is not yours, ask the owner for grant access\"}";
                server.send(errorMessage, ipAddress);
            }
        }
        else
        {
            string errorMessage="{\"message\":\"error\",\"type\":\"Register for accelerometer failed :: incorrect index\"}";
            server.send(errorMessage, ipAddress);
        }
        
        return;
    }
    else if(message == "releaseAccelerometer")
    {
        int deviceIndex = args.json.get("device", -1).asInt();
        string ipAddress = args.conn.getClientIP();
        vector<string> *vTmp=&registeredForAccelerometer[deviceIndex];
       
        auto it = std::find(vTmp[deviceIndex].begin(), vTmp[deviceIndex].end(),ipAddress);
        
        if( it!= vTmp[deviceIndex].end())
        {
            vTmp->erase(it);
        }
        else
        {
            string errorMessage="{\"message\":\"error\",\"type\":\"Release accelerometer : not present in listeners\"}";
            server.send(errorMessage, ipAddress);
        }
     
    }
    else if(message == "registerShake")
    {
        int deviceIndex = args.json.get("device", -1).asInt();
        string ipAddress = args.conn.getClientIP();
        
        if(deviceIndex<=MAX_NUM_OF_DEVICES && deviceIndex>=0 && deviceIndex<numOfConnectedDevices)
        {
            if(registeredForShake.find(deviceIndex)==registeredForShake.end() )
            {
                bool ipPresent = false;
                for (std::map<int, string>::iterator it=registeredForShake.begin(); it!=registeredForShake.end(); it++) {
                    string ipTmp=it->second;
                    if(ipTmp==ipAddress)
                    {
                        ipPresent=true;
                    }
                }
                if(!ipPresent){
                    
                    [bleDeviceMap[deviceIndex].accelerometer.shakeEvent startNotificationsWithHandler:^(id obj, NSError *error) {
                        string newMessage="{\"message\":\"shakeEvent\"}";
                        server.send(newMessage, ipAddress);

                    }];
                    
                    registeredForShake[deviceIndex]=ipAddress;
                }
                else
                {
                    string errorMessage="{\"message\":\"error\",\"type\":\"Register for shake failed :: ip address already registered for this event\"}";
                    server.send(errorMessage, ipAddress);
                }
            }
        }
        else
        {
            string errorMessage="{\"message\":\"error\",\"type\":\"Register for shake failed :: incorrect index\"}";
            server.send(errorMessage, ipAddress);
        }
        
        return;
    }
    else if(message == "releaseShake")
    {
        int deviceIndex = args.json.get("device", -1).asInt();
        string ipAddress = args.conn.getClientIP();
        
        
        
        for (std::map<int, string>::iterator it=registeredForShake.begin(); it!=registeredForShake.end(); it++) {
            string ipTmp=it->second;
            if(ipTmp==ipAddress)
            {
                [bleDeviceMap[it->first].accelerometer.shakeEvent stopNotifications];
                registeredForShake.erase(deviceIndex);
                registeredForShake.erase(it, it);
                registeredForShake.erase(it->first);
                break;
            }
        }
    }
    else if(message == "registerTap")
    {
        int deviceIndex = args.json.get("device", -1).asInt();
        string ipAddress = args.conn.getClientIP();
        
        if(deviceIndex<=MAX_NUM_OF_DEVICES && deviceIndex>=0 && deviceIndex<numOfConnectedDevices)
        {
            if(registeredForTap.find(deviceIndex)==registeredForTap.end() )
            {
                bool ipPresent = false;
                for (std::map<int, string>::iterator it=registeredForTap.begin(); it!=registeredForTap.end(); it++) {
                    string ipTmp=it->second;
                    if(ipTmp==ipAddress)
                    {
                        ipPresent=true;
                    }
                }
                if(!ipPresent){
                    
                    [bleDeviceMap[deviceIndex].accelerometer.tapEvent startNotificationsWithHandler:^(id obj, NSError *error) {
                        string newMessage="{\"message\":\"tapEvent\"}";
                        server.send(newMessage, ipAddress);
                        
                    }];
                    
                    registeredForTap[deviceIndex]=ipAddress;
                }
                else
                {
                    string errorMessage="{\"message\":\"error\",\"type\":\"Register for tap failed :: ip address already registered for this event\"}";
                    server.send(errorMessage, ipAddress);
                }
            }
        }
        else
        {
            string errorMessage="{\"message\":\"error\",\"type\":\"Register for tap failed :: incorrect index\"}";
            server.send(errorMessage, ipAddress);
        }
        
        return;
    }
    else if(message == "releaseTap")
    {
        int deviceIndex = args.json.get("device", -1).asInt();
        string ipAddress = args.conn.getClientIP();
        
        
        
        for (std::map<int, string>::iterator it=registeredForTap.begin(); it!=registeredForTap.end(); it++) {
            string ipTmp=it->second;
            if(ipTmp==ipAddress)
            {
                [bleDeviceMap[it->first].accelerometer.shakeEvent stopNotifications];
                registeredForTap.erase(deviceIndex);
                registeredForTap.erase(it, it);
                registeredForTap.erase(it->first);
                break;
            }
        }
    }
    else if(message == "registerTemperature")
    {
        int deviceIndex = args.json.get("device", -1).asInt();
        string ipAddress = args.conn.getClientIP();
        
        if(deviceIndex<=MAX_NUM_OF_DEVICES && deviceIndex>=0 && deviceIndex<numOfConnectedDevices)
        {
            if(registeredForTemperature.find(deviceIndex)==registeredForTemperature.end())
            {
                bool ipPresent = false;
                for (std::map<int, string>::iterator it=registeredForTemperature.begin(); it!=registeredForTemperature.end(); it++) {
                    string ipTmp=it->second;
                    if(ipTmp==ipAddress)
                    {
                        ipPresent=true;
                    }
                }
                if(!ipPresent){
                     bleDeviceMap[deviceIndex].temperature.samplePeriod = 2000;
                    [ bleDeviceMap[deviceIndex].temperature.dataReadyEvent startNotificationsWithHandler:^(NSDecimalNumber* temp, NSError *error) {
                        string suffix = bleDeviceMap[deviceIndex].temperature.units == MBLTemperatureUnitCelsius ? "°C" : "°F";
                        
                        NSString *decimalString =  [NSString stringWithFormat:@"%@",temp];
                        decimalString = [[decimalString componentsSeparatedByString:@" "] objectAtIndex:4] ;
                        string tempTmp = ofToString([decimalString UTF8String] )+suffix;
                        
                        tempTmp = "{\"message\":\"temperatureEvent\",\"value\":\""+tempTmp+"\"}";
                        
                        server.send(tempTmp, ipAddress);

                    }];
                   
                    registeredForTemperature[deviceIndex]=ipAddress;
                }
            }
        }
        else
        {
            string errorMessage="{\"message\":\"error\",\"type\":\"Register for shake failed :: incorrect index\"}";
            server.send(errorMessage, ipAddress);
        }
        
        
        return;
    }
    else if(message == "releaseTemperature")
    {
        int deviceIndex = args.json.get("device", -1).asInt();
        string ipAddress = args.conn.getClientIP();
        
        
        
        for (std::map<int, string>::iterator it=registeredForTemperature.begin(); it!=registeredForTemperature.end(); it++) {
            string ipTmp=it->second;
            if(ipTmp==ipAddress)
            {
                [bleDeviceMap[it->first].temperature.dataReadyEvent stopNotifications];
                registeredForTemperature.erase(deviceIndex);
                registeredForTemperature.erase(it, it);
                registeredForTemperature.erase(it->first);
                break;
            }
        }
    }
    else if(message == "registerForFreeFall")
    {
        int deviceIndex = args.json.get("device", -1).asInt();
        string ipAddress = args.conn.getClientIP();
        
        if(deviceIndex<=MAX_NUM_OF_DEVICES && deviceIndex>=0 && deviceIndex<numOfConnectedDevices)
        {
            if(registeredForFreeFall.find(deviceIndex)==registeredForFreeFall.end())
            {
                bool ipPresent = false;
                for (std::map<int, string>::iterator it=registeredForFreeFall.begin(); it!=registeredForFreeFall.end(); it++) {
                    string ipTmp=it->second;
                    if(ipTmp==ipAddress)
                    {
                        ipPresent=true;
                    }
                }
                if(!ipPresent){
                   
                    [ bleDeviceMap[deviceIndex].accelerometer.freeFallEvent startNotificationsWithHandler:^(MBLEvent *freeFallEvent, NSError *error) {

                        string newMessage = "{\"message\":\"registerForFreeFall\"}";
                        
                        server.send(newMessage, ipAddress);
                        
                    }];
                    
                    registeredForFreeFall[deviceIndex]=ipAddress;
                }
            }
        }
        else
        {
            string errorMessage="{\"message\":\"error\",\"type\":\"Register for free fall failed :: incorrect index\"}";
            server.send(errorMessage, ipAddress);
        }
        
        
        return;
    }
    else if(message == "releaseFreeFall")
    {
        int deviceIndex = args.json.get("device", -1).asInt();
        string ipAddress = args.conn.getClientIP();
        
        
        
        for (std::map<int, string>::iterator it=registeredForFreeFall.begin(); it!=registeredForFreeFall.end(); it++) {
            string ipTmp=it->second;
            if(ipTmp==ipAddress)
            {
                [bleDeviceMap[it->first].accelerometer.freeFallEvent stopNotifications];
                registeredForFreeFall.erase(deviceIndex);
                registeredForFreeFall.erase(it, it);
                registeredForFreeFall.erase(it->first);
                break;
            }
        }
    }
    else if(message == "makeVibrate")
    {
        int deviceIndex = args.json.get("device", -1).asInt();
        string ipAddress = args.conn.getClientIP();
        uint8_t dcycle = 500;
        uint16_t pwidth = 248;
        
        if(args.json.get("hasOptions",-1).asBool())
        {
            dcycle =ofClamp(args.json.get("dcycle", 500).asInt(),0,5000);
            pwidth = ofClamp(args.json.get("pwidth",248).asInt(),0,248);
        }
        if(deviceIndex<=MAX_NUM_OF_DEVICES && deviceIndex>=0 && deviceIndex<numOfConnectedDevices)
        {
            [bleDeviceMap[deviceIndex].hapticBuzzer startHapticWithDutyCycle:dcycle pulseWidth:pwidth completion:nil];
        }
    }
}

//--------------------------------------------------------------
void ofApp::onBroadcast( ofxLibwebsockets::Event& args ){
    cout<<"got broadcast "<<args.message<<endl;
}
//--------------------------------------------------------------
void ofApp::sendMessageWithDelay( string message ){
    server.send(message);
}
/****************
 ******
COMMUNICATION WITH BLE
 ****************/
//--------------------------------------------------------------
void ofApp::initStructures(){
    for (int i=0; i<MAX_NUM_OF_DEVICES; i++) {
        bleDeviceMap[i] = NULL;
    }
    for (int i=0; i<MAX_NUM_OF_DEVICES; i++) {
        bleIPMap[i] = "";
    }
    
}
//--------------------------------------------------------------
void ofApp::assignIPToDevice(string ip){
    for (int i=0; i<MAX_NUM_OF_DEVICES; i++) {
        if(bleDeviceMap[i]!=NULL && bleIPMap[i] == "")
        {
            bleIPMap[i] = ip;
            string notifyMessage="{\"message\":\"bleAssigned\",\"number\":\""+ofToString(i)+"\"}";
            server.send(notifyMessage   , ip);
            return;
        }
    }
}
//--------------------------------------------------------------
void ofApp::retractIPToDevice(string ip){
    for (int i=0; i<MAX_NUM_OF_DEVICES; i++) {
        if(bleDeviceMap[i]!=NULL && bleIPMap[i] == ip)
        {
            bleIPMap[i] = "";
            return;
        }
    }
}
//--------------------------------------------------------------
void ofApp::assignIPToDevices(){
    for (int k=0; k<MAX_NUM_OF_DEVICES; k++) {
        if (bleIPMap[k]!="" && bleDeviceMap[k]!=NULL) {
            string notifyMessage="{\"message\":\"bleAssigned\",\"number\":\""+ofToString(k)+"\"}";
            server.send(notifyMessage   , bleIPMap[k]);
        }
    }
}
//--------------------------------------------------------------
void ofApp::setColor(int boardNumber,int red, int green, int blue){
  
}
//--------------------------------------------------------------
void ofApp::sendAccelerometerData(){
    if(ofGetElapsedTimef()-timePassedSinceLastSentData>0.2)
    {
        for (int i=0; i<MAX_NUM_OF_DEVICES; i++) {
            if ( bleDeviceMap[i]!=NULL) {
                string newMessage="{\"message\":\"accelerometerEvent\",\"x\":\""+ofToString(accValues[i].x)+"\",\"y\":\""+ofToString(accValues[i].y)+"\",\"z\":\""+ofToString(accValues[i].z)+"\"}";
                for(std::vector<string>::iterator it=registeredForAccelerometer[i].begin();it<registeredForAccelerometer[i].end();it++ )
                {
                    string sTmp=*it;
                    server.send(newMessage, sTmp);
                }
            }
        }
        timePassedSinceLastSentData = ofGetElapsedTimef();
    }
}