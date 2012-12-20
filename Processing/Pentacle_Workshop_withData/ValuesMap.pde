// public class ValuesMap {} //CLASS-IFY MANG

//All Euler<>Quanterion translations taken from work of F. Varesio

//Arrays Arduino Data and translations1
static public float [] q = new float [4];
static public float [] hq = null;
static public float [] euler = new float [3]; // psi, theta, phi
static public int [] piezo = new int [12];

int piezoNumber;
int piezoVal;

String message;

// Serial FreeIMU values decoding system, thanks Fabio!

float decodeFloat(String inString) {
  byte [] inData = new byte[4];
  if (inString.length() == 8) {
    inData[0] = (byte) unhex(inString.substring(0, 2));
    inData[1] = (byte) unhex(inString.substring(2, 4));
    inData[2] = (byte) unhex(inString.substring(4, 6));
    inData[3] = (byte) unhex(inString.substring(6, 8));
  }
// one day I'll understand bitshifting......
  int intbits = (inData[3] << 24) | ((inData[2] & 0xff) << 16) | ((inData[1] & 0xff) << 8) | (inData[0] & 0xff);
  return Float.intBitsToFloat(intbits);
}

//My Arduino input reading system ( super hack-0y) just looks at length of serial line to distinguish messages.
void readQ() {
  if (myPort.available() >= 18) {
    String inputString = myPort.readStringUntil('\n');

    //  print(inputString);

    if (inputString != null && inputString.length() > 0) {
      String [] inputStringArr = split(inputString, ",");
      if (inputStringArr.length >= 5) { // q1,q2,q3,q4,\r\n so we have 5 elements
        q[0] = decodeFloat(inputStringArr[0]);
        q[1] = decodeFloat(inputStringArr[1]);
        q[2] = decodeFloat(inputStringArr[2]);
        q[3] = decodeFloat(inputStringArr[3]);
      }
      else if (inputStringArr.length == 3) {
        piezoNumber = Integer.parseInt(inputStringArr[0]);
        piezoVal =  Integer.parseInt(inputStringArr[1]);
        piezo[(piezoNumber)] = piezoVal;
        //testing
     //   println(piezoNumber);
      //  println(piezoVal);
      }
      else if (inputStringArr.length == 1) {
        //testing
       // println("FREEFALL");
        freefall = true;
      }
    }
    else { 
      for ( int i = 0 ; i < piezo.length; i++) {
        piezo[i] = 0;
        freefall = false;
      }
    }
  }
}

// See Sebastian O.H. Madwick report 
// "An efficient orientation filter for inertial and intertial/magnetic sensor arrays" Chapter 2 Quaternion representation

void quaternionToEuler(float [] q, float [] euler) {
  euler[0] = atan2(2 * q[1] * q[2] - 2 * q[0] * q[3], 2 * q[0]*q[0] + 2 * q[1] * q[1] - 1); // psi
  euler[1] = -asin(2 * q[1] * q[3] + 2 * q[0] * q[2]); // theta
  euler[2] = atan2(2 * q[2] * q[3] - 2 * q[0] * q[1], 2 * q[0] * q[0] + 2 * q[3] * q[3] - 1); // phi
}

float [] quatProd(float [] a, float [] b) {
  float [] q = new float[4];

  q[0] = a[0] * b[0] - a[1] * b[1] - a[2] * b[2] - a[3] * b[3];
  q[1] = a[0] * b[1] + a[1] * b[0] + a[2] * b[3] - a[3] * b[2];
  q[2] = a[0] * b[2] - a[1] * b[3] + a[2] * b[0] + a[3] * b[1];
  q[3] = a[0] * b[3] + a[1] * b[2] - a[2] * b[1] + a[3] * b[0];

  return q;
}


// returns a quaternion from an axis angle representation
float [] quatAxisAngle(float [] axis, float angle) {
  float [] q = new float[4];

  float halfAngle = angle / 2.0;
  float sinHalfAngle = sin(halfAngle);
  q[0] = cos(halfAngle);
  q[1] = -axis[0] * sinHalfAngle;
  q[2] = -axis[1] * sinHalfAngle;
  q[3] = -axis[2] * sinHalfAngle;

  return q;
}

// return the quaternion conjugate of quat
float [] quatConjugate(float [] quat) {
  float [] conj = new float[4];

  conj[0] = quat[0];
  conj[1] = -quat[1];
  conj[2] = -quat[2];
  conj[3] = -quat[3];

  return conj;
}

