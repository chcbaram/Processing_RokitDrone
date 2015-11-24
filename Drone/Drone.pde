/**
 Basic demonstration of using a gamepad.
 
 When this sketch runs it will try and find
 a game device that matches the configuration
 file 'gamepad' if it can't match this device
 then it will present you with a list of devices
 you might try and use.
 
 The chosen device requires 3 sliders and 2 button.
 */

import org.gamecontrolplus.gui.*;
import org.gamecontrolplus.*;
import net.java.games.input.*;
import processing.serial.*;

// The serial port:
Serial mSerial;       




DroneFighter mDrone;


ControlIO control;
Configuration config;
ControlDevice gpad;


float LeftPad_PosX;
float LeftPad_PosY;

float RightPad_PosX;
float RightPad_PosY;

float eyeRad   = 80;
float eyeSize  = eyeRad * 2;
float browSize =  eyeSize * 1.2f, browFactor;
float irisRad = 42, irisSize = irisRad * 2;

float roll = 0;
float pitch = 0;
float yaw = 0;
float thrust = 0;


float pad_roll = 0;
float pad_pitch = 0;
float pad_yaw = 0;
float pad_thrust = 0;

int cmd_timer;


int Sem = 0;




public void setup() 
{
 
  size(400, 240);
  // Initialise the ControlIO
  control = ControlIO.getInstance(this);
  // Find a device that matches the configuration file
    
  gpad = control.getMatchedDevice("skyrover");
  if (gpad == null) 
  {
    println("No suitable device configured");
    System.exit(-1); // End the program NOW!
  }


  mDrone = new DroneFighter();
  
  // List all the available serial ports:
  printArray(Serial.list());
  mSerial = new Serial(this, Serial.list()[7], 9600);
}

public void draw() 
{
  background(255, 200, 255);
  
  textSize(14);
  text("Start : c ", 5, 15);
  
  if( mDrone.isConnected() )
    text("Status : Connected", 5, 15*2);
  else
    text("Status : Disconnected", 5, 15*2);
  
  
  pad_roll  = gpad.getSlider("ROLL").getValue();
  pad_pitch = gpad.getSlider("PITCH").getValue();
  pad_yaw   = gpad.getSlider("YAW").getValue();
  pad_thrust= gpad.getSlider("THRUST").getValue();
  
  
  //-- Send Command
  //  
  if( (millis()-cmd_timer) >= 100 )
  {
    cmd_timer = millis();
    
    if( mDrone.isConnected() )
    {
      //-- roll
      roll = pad_roll * 100;
      
      //-- pitch
      pitch = -pad_pitch * 100;

      //-- yaw
      yaw = pad_yaw * 100;

      
      //-- thrust 
      thrust = - pad_thrust * 100;
      
      
      //mDrone.sendCommandPacket((float)roll, (float)pitch, (float)yaw, (char)thrust);
      
      if( Sem == 0 )
      {
        if( thrust > -90 )
        {
          SendPacket( (int)roll, (int)pitch, (int)yaw, (int)thrust, (byte)0 );
        }
        else
        {
          SendPacket( (int)roll, (int)pitch, (int)yaw, (int)thrust, (byte)0xA1 ); // 0xA1 STOP
        }
      }      
    }
  }
  
  
  LeftPad_PosX = pad_roll  * (eyeSize-irisSize)/2;
  LeftPad_PosY = pad_pitch * (eyeSize-irisSize)/2;
  RightPad_PosX = pad_yaw  * (eyeSize-irisSize)/2;
  RightPad_PosY = pad_thrust * (eyeSize-irisSize)/2;
  
  
  // Draw Pad
  drawPad(0, 100, 140);
  drawPad(1, 300, 140);
}


public void drawPad(int type, int x, int y) {
  
  pushMatrix();
  translate(x, y);

  // draw white of eye
  stroke(0, 96, 0);
  strokeWeight(3);

  fill(255);
  ellipse(0, 0, eyeSize, eyeSize);

  // draw iris
  noStroke();
  fill(120, 100, 220);
  
  if( type == 0 )
    ellipse(LeftPad_PosX, LeftPad_PosY, irisSize, irisSize);
  else
    ellipse(RightPad_PosX, RightPad_PosY, irisSize, irisSize);

  popMatrix();
  
}


void keyPressed() 
{

  if ( key == 'c' ) 
  {
    mDrone.connect();    
  } 
  
  
  if ( key == 's' ) 
  {
    Sem = 1;
    println("Send");
    SendPacket( 0, 0, 0, 0, (byte)0xB1 ); // EVENT  B1 RESET YAW, A1 STOP    
    Sem = 0;
  }
}


void serialEvent(Serial p) 
{ 
  if( p.available() > 0 )
  {
    int inByte = p.read();
    
    //println( String.format("0x%02x", inByte));
    
    PacketReceive( (byte)inByte );
    
  }
} 


void SendPacket( int Roll, int Pitch, int Yaw, int Throttle, byte EventData )
{
    byte[] Packet = new byte[10];
    byte   CheckSum;
    byte   ByteRoll;

    ByteRoll = (byte)Roll;

    //println(ByteRoll);
    println( String.format("0x%02x", ByteRoll)); 

    // Start
    Packet[0] = 0x0A;
    Packet[1] = 0x55;
    
    // Header
    Packet[2] = 0x20;
    Packet[3] = 0x05;
    
    Packet[4] = ByteRoll;
    Packet[5] = (byte)Pitch;
    Packet[6] = (byte)Yaw;
    Packet[7] = (byte)Throttle;
    Packet[8] = (byte)EventData;
    
    CheckSum = 0;
    for( int i=2; i<9; i++ )
    {
      CheckSum = (byte)(CheckSum + Packet[i]);  
    }
    Packet[9] = CheckSum;
    
    mSerial.write( Packet ); 
    
    /*
    for( int i=0; i<10; i++ )
    {
      mSerial.write( (byte)Packet[i] );
    }
    */
}


final int MAX_CMD_LENGTH = 11;


  byte cmdBuff[] = new byte[MAX_CMD_LENGTH];
  byte startBuff[] = new byte[2];
  int cmdIndex;
  int checkHeader;

  boolean SuccessReceive = false;
  int team;
  int flightStatus;
  int energy;
  int battery;
  int missileQuantity;


void PacketReceive( byte ByteData )
{  
  SuccessReceive = false;
  team = -1;
  flightStatus = -1;
  energy = -1;
  battery = -1;
  missileQuantity  = -1;
          
  {
    int input = ByteData;
    cmdBuff[cmdIndex++] = (byte)input;
    
    startBuff[0] = startBuff[1];
    startBuff[1] = (byte)input;
    
    if (cmdIndex >= MAX_CMD_LENGTH)
    {
      checkHeader = 0;
      cmdIndex = 0;
    }
    else
    {
      
      if ((startBuff[0] == 0x0A) && (startBuff[1] == 0x55) && (checkHeader == 0) )
      {
        checkHeader = 1;
        cmdIndex = 2;
        cmdBuff[0] = startBuff[0];
        cmdBuff[1] = startBuff[1]; 
      }
      else
      {
        if( checkHeader == 0 )
        {
          checkHeader = 0;
          cmdIndex = 0;
        }
      }
      
      /*
      if (cmdIndex == 2)
      {
        if ((cmdBuff[0] == 0x0A) && (cmdBuff[1] == 0x55))
        {
          checkHeader = 1;
          println("Start");
        }
        else
        {
          checkHeader = 0;
          cmdIndex = 0;
        }
      }
      */
      
      if (checkHeader == 1)
      {
        if (cmdIndex == 3)
        {
          if (cmdBuff[2] == 0x21)
          {
            int type = cmdBuff[2];
            checkHeader = 2;             
          }
          else
          {
            checkHeader = 0;
            cmdIndex = 0;
          }
        }
      }

      if (checkHeader == 2)
      {
        if (cmdIndex == 4)
        {
          int length = cmdBuff[3];
        }

        else if (cmdIndex == 10)
        {
          int cs = cmdBuff[9];

          byte  checkSum = 0;
          for (int i = 2; i < 9; i++)
          {
            checkSum += cmdBuff[i];
          }
          
          if (cs == checkSum)
          {
            SuccessReceive = true;
            
            team = cmdBuff[4];
            flightStatus = cmdBuff[5];
            energy = cmdBuff[6];
            battery = cmdBuff[7];
            missileQuantity = cmdBuff[8];   
            print("team "); print(team); print(" ");
            print("flightStatus "); print(flightStatus); print(" ");
            print("energy "); print(energy); print(" ");
            print("battery "); print(battery&0xFF);  print(" ");
            print("missileQuantity "); print(missileQuantity); println(" ");
            
          }
   
          checkHeader = 0;
          cmdIndex = 0;
        }
      }
    }
  }
}