
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;



public class DroneFighter {
  
    private boolean mSetupFinished;

    public DroneFighter() {        
        mSetupFinished = false;
    }

    public void connect() {
          mSetupFinished = true;
    }


    public void disconnect() {
        mSetupFinished = false;
    }

    public void sendCommandPacket(float roll, float pitch, float yaw, char thrust) {
        /*
        // TODO: if(mCrazyflie.isConnected()) {
        if(mCrazyflie.getState().ordinal() >= State.CONNECTED.ordinal()) {
            mCrazyflie.sendPacket(new CommanderPacket(roll, pitch, yaw, thrust));
        } else {
            System.err.println("No crazyflie connected.");
        }
        */
    }



    public boolean isConnected() { return mSetupFinished; }
  

}
