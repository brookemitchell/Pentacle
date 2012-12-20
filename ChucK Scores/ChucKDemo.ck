//Brooke Mitchell Pentacle Demo Code

//Load all samples into strings
"./wavs/0.wav" => string sample0;
"./wavs/11.wav" => string sample1;
"./wavs/1.wav" => string sample2;
"./wavs/2.wav" => string sample3;
"./wavs/3.wav" => string sample4;
"./wavs/4.wav" => string sample5; // Piano pluck, high sounds good
"./wavs/5.wav" => string sample6;
"./wavs/6.wav" => string sample7;
"./wavs/7.wav" => string sample8;
"./wavs/8.wav" => string sample9;
"./wavs/9.wav" => string sample10;
"./wavs/10.wav" => string sample11;

// setup the instrument output patch 
SndBuf buff[12];
Gain gainBuff => Gain instMaster => dac;


//patch array
for (0 => int i; i < buff.cap(); i++){
    buff[i] => gainBuff;

}

//Setup effects(pitshift and ifft) and FFT(to be sent over OSC)
adc.chan(0) => Gain g1 => LPF lpf1 => FFT fft => blackhole;
g1 => IFFT ifft =>  Gain fftGain => LPF lpf2 => PitShift pShift => JCRev r => Gain effects => Gain adcMaster => dac.chan(1); 
g1 => Gain dry => adcMaster; // monitor the input
fft =^ RMS rms => blackhole;

//init gain levels
0=> gainBuff.gain;
3=> dry.gain;
2=> adcMaster.gain;



OscRecv recv;
12000 => recv.port;
recv.listen();

recv.event("/euler, fff") @=> OscEvent eulerEvent;
recv.event("/piezo, iiiiiiiiiiii") @=> OscEvent piezoEvent;
recv.event("/freefall, i") @=> OscEvent freefallEvent;

// OSC send settings and init
"localhost" => string HOST_NAME;
12000 => int OSC_PORT_OUT;
OscSend xmit;
xmit.setHost(HOST_NAME, OSC_PORT_OUT);

//FFT Blobs
UAnaBlob blob;
UAnaBlob blob2;

//Set Sameple Rate
44100.0 => float SAMPLE_RATE;

//Set FFT/IFFT Parameters
4096 => fft.size => int FFT_SIZE; // Frequency Resolution
1024 => ifft.size => int WINDOW_SIZE;
WINDOW_SIZE/2 => int HOP_SIZE; //Iteration number of samples (overlap)

// set controlling parameters
4096 => int num_samples;            // number of samples per fft, use binary multiple
2 => float overlap_factor;          // overlaps the fft window, use number > 1
0.25 => float af;                   // amplitude decay factor
1.8 => float k;                    // second voice is at this multiple
1 => int n;                         // number of voices to add in addition to original voice


// set fft gains
0.5 / (n + 1) => fftGain.gain;

// set up filters
lpf1.freq(10000);
lpf2.freq(10000);

// set windowing
Windowing.hann(WINDOW_SIZE) => fft.window;
Windowing.hann(WINDOW_SIZE) => ifft.window;

// declare variables
num_samples / 2  => int num_freq;
complex spec_in[FFT_SIZE/2];
complex spec_out[FFT_SIZE/2];
string fft_string;
string next_char;

float Z[FFT_SIZE/2]; // FFT Analysis Array ( to Nyquist)
int MaxI; // Store Peak Value index (bbin) in FF

//.3 => rev.mix;
// load the file
sample0 => buff[0].read;
sample1 => buff[1].read;
sample2 => buff[2].read;
sample3 => buff[3].read;
sample4 => buff[4].read;
sample5 => buff[5].read;
sample6 => buff[6].read;
sample7 => buff[7].read;
sample8 => buff[8].read;
sample9 => buff[9].read;
sample10 => buff[10].read;
sample11 => buff[11].read;



float EulerValues[3];
int PiezoValues[12];
Event freefall;

fun void eulerPoller(){
    while (true){
        eulerEvent => now;
        if (eulerEvent.nextMsg() != 0){
            for( 0 => int i; i < EulerValues.cap(); i++) //callin' slider values, all f
                eulerEvent.getFloat() => EulerValues[i];
            eulerEvent.broadcast();
        }
        //testing stuff
            EulerValues[0], EulerValues[1], EulerValues[2];
    }
}

fun void piezoPoller(){
    while (true){
        piezoEvent => now;
        if (piezoEvent.nextMsg() != 0){
            
            for( 0 => int i; i < PiezoValues.cap(); i++) {
                piezoEvent.getInt() => PiezoValues[i];
                piezoEvent.broadcast();            
            }
        }
        //more testing stuff
        /*                
        <<<PiezoValues[0], PiezoValues[1], PiezoValues[2], PiezoValues[3], PiezoValues[4],
        PiezoValues[5], PiezoValues[6], PiezoValues[7], PiezoValues[8], PiezoValues[9], 
        PiezoValues[10], PiezoValues[11]>>>;
        */
    }
}

fun void freefallPoller(){
    while (true){
        
        freefallEvent => now;
        while(freefallEvent.nextMsg() != 0){
            //  freefallEvent.getInt() => freefall;
            freefallEvent.broadcast();
            
            //  <<<"Freefall!!!">>>;
            
            
            for( 0 => int i; i < 12 ; i++)
            {
                Math.tanh(buff[i].freq()) => buff[i].freq;
                
            }
            
            1::ms=>now;
            
        }
    }
    
}

fun void actionThread(){
    while (true){
        
        
        
        EulerValues[1]%20 => pShift.shift;
        EulerValues[2]*.9 => pShift.mix;
        1.5 + EulerValues[0] + k;                    // second voice is at this multiple 
        
        // hang for a bit
        10::ms => now;
        
                
        for( 0 => int i; i < 12 ; i++)
        {
            EulerValues[1]/4 => buff[i].gain;
            EulerValues[0]/400=> buff[i].rate;
            EulerValues[2] => buff[i].freq;
            
            if(PiezoValues[i] > 0)
            {
                PiezoValues[i] => buff[i].pos;
                //testing printout
                // <<<i,":",PiezoValues[i]>>>;
            }
            else {
            }
        }        
        Std.rand2(66,666)::ms => now;         
        
        
        
    }
}

fun void fftThread(){
    num_samples::samp => now;
    while( true )
    {
        // take fft, save output as a UAnaBlob, and extract complex spectrum
        fft.upchuck().cvals() @=> spec_in;
        
        // copy input spectrum into output spectrum  
        spec_in @=> spec_out;
        
        // copy the voice at fractional harmonic
        for (1 => int ni; ni <= n; ni++) {
            Math.pow (k, ni) => float fraction;
            for (0 => int i; i < num_freq; i++) {
                (fraction * i) $ int => int i_out;
                if ((i_out > 0) && (i_out < num_freq)) {
                    2 / ni * spec_in[i] +=> spec_out[i_out];
                }
            }
        }
        
        // do ifft on the transformed spectrum
        ifft.transform(spec_out);
    
    // advance time
    fft.size()::samp / overlap_factor => now;        
}
}


fun void fftprocess(){
    while(true){  
        
        //stick fft and rms in blob(s)
        fft.upchuck() @=> blob;        
        rms.upchuck() @=>  blob2;
        
        //make rms val scaleto something more more useful
        blob2.fval(0) * 1000 => float rmsVal;
        
        for (0 => int i; i < Z.cap(); i++){
            // array strore simplifed fft value
            fft.fval(i) => Z[i];
        }
        //MaxIndexFunction
        MaxIndex(Z) => MaxI;
        //OSC send those values
        intSend("/peak", MaxI);    
        floatSend("/rms", rmsVal);
        //pass time between windows
        HOP_SIZE::samp => now;
    }
}

fun int MaxIndex(float A[]){
    
    //Value is max amp value, index location is freq bin place where max hit
    0.0 => float tempMaxValue;
    int prevIndex;
    0 => int tempMaxIndex;
    
    
    for(250 => int i; i < A.cap(); i++){
        
        
        if(tempMaxValue < A[i]   ){
            
            A[i] => tempMaxValue;
if(i != prevIndex){
    i=> tempMaxIndex;
        }
                    i => prevIndex;

        }
    }
    
    return tempMaxIndex;
}

fun float Bin2Freq(int bin, float sr, int fftsize){
    float freq;
    //magic equation - derived from standard unit thing
    (bin*sr)/fftsize => freq;
    
    return freq;
    
}


fun void intSend(string Msg,int i){
    //Osc Message ident
    xmit.startMsg(Msg, "i");
    //Transmit temp
      // <<<i>>>;
        i => xmit.addInt;
    
}

fun void floatSend(string Msg, float f1){
    //Osc Message ident
    xmit.startMsg(Msg, "f");
    //Transmit temp
    f1 => xmit.addFloat;
    // <<<f1>>>;
    
}



spork ~eulerPoller();
spork ~piezoPoller();
spork ~freefallPoller();
spork ~actionThread();
spork ~fftThread();
spork ~fftprocess();


// time loop
while( true )
{     
    
    //sequence of events for live performance. see visual score.
    0 => effects.gain;
    0 => gainBuff.gain;
    4::second => now;
    .5 => gainBuff.gain;
    0 => effects.gain;
    36::second => now;
    .5 => gainBuff.gain;
    0 => effects.gain;
    40::second => now;
    .5 => gainBuff.gain;
    0 => effects.gain;
    40::second => now;
    .5 => gainBuff.gain;
    for( 0.0 => float f; f < 0.028;  .001 +=> f){        
        f => effects.gain;
        10::ms => now;
    }
    1::minute => now;
    .5 => gainBuff.gain;
    for(0.028=> float f ; f > 0.0; .001 -=> f){        
        f => effects.gain;
        10::ms => now;
    }
    0 => effects.gain;
    1::minute => now;
    .5 => gainBuff.gain;
    for(0.0 => float f ; f < 0.028; .001 +=> f){        
        f => effects.gain;
        10::ms => now;
    }    
    1::day => now;      
}