package net.mgsx.pd;

import java.io.File;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.ShortBuffer;

import javax.sound.sampled.AudioFileFormat;
import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.UnsupportedAudioFileException;

import org.puredata.core.PdBase;

public class PdProcessor {

	public static class FakeStream extends TargetDataLineAdapter
	{
		private AudioInputStream inStream;
		
		int ticks = 64;
		
		byte [] rawInput;
		byte [] rawOutput;
		short [] pdInput;
		short [] pdOutput;
		ShortBuffer inputBuffer;
		ShortBuffer outputBuffer;
		
		int outputRead, outputWrite;
		
		public FakeStream(AudioInputStream inStream) {
			
			this.inStream = inStream;
			PdBase.openAudio(inStream.getFormat().getChannels(), inStream.getFormat().getChannels(), (int)inStream.getFormat().getFrameRate());
			PdBase.computeAudio(true);
			
			try {
				PdBase.openPatch(new File("patch.pd"));
			} catch (IOException e) {
				throw new Error(e);
			}
			PdBase.sendFloat("freq", 5000);
			PdBase.sendFloat("q", 10);

			int frames = PdBase.blockSize() * ticks;
			pdInput = new short[frames * inStream.getFormat().getChannels()];
			pdOutput = new short[frames * inStream.getFormat().getChannels()];
			
			rawInput = new byte[pdInput.length * 2];
			rawOutput = new byte[pdOutput.length * 2];
			inputBuffer = ByteBuffer.wrap(rawInput).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer();
			outputBuffer = ByteBuffer.wrap(rawOutput).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer();
		}
		@Override
		public AudioFormat getFormat() {
			return inStream.getFormat(); // new AudioFormat(96000, 16, 1, true, false);
		}
		
		int CNT = 0;
		
		@Override
		public int read(byte[] b, int off, int len) 
		{
			int c = 0;
			while(c < len && outputWrite >= 0)
			{
				for(int i=outputRead ; c<len && i<outputWrite ; i++)
				{
					b[c+off] = rawOutput[i];
					c++;
					outputRead++;
				}
				if(c < len)
				{
					outputRead = 0;
					try {
						outputWrite = inStream.read(rawInput);
					} catch (IOException e) {
						throw new Error(e);
					}
					inputBuffer.rewind();
					inputBuffer.get(pdInput);
					for(int i=outputWrite ; i<rawInput.length ; i+=2)
					{
						pdInput[i/2] = 0;
					}
					PdBase.process(ticks, pdInput, pdOutput);
					
					outputBuffer.rewind();
					outputBuffer.put(pdOutput);
					
				}
			}
			return c;
		}
		
	}
	
	public static void main(String[] args) throws UnsupportedAudioFileException, IOException 
	{
		String path = "mixdown.wav";
		
		AudioInputStream stream = AudioSystem.getAudioInputStream(new File(path));
		
		AudioSystem.write(new AudioInputStream(new FakeStream(stream)), AudioFileFormat.Type.WAVE, new File("gen.wav"));
	}

}
