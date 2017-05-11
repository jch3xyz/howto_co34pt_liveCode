//Boilerplate code for basic live coding functionality


(
//increase number of buffers the server has access to for loading samples
s.options.numBuffers = 1024 * 16;
//increase the memory available to the server
s.options.memSize = 8192 * 64;
//boot the server, wait until it has booted, then execute the following
s.waitForBoot({
	//display the oscilloscope
	s.scope;
	//start proxyspace
	p=ProxySpace.push(s);
	//start tempo clock
	p.makeTempoClock;
	//give proxyspace a tempo
	p.clock.tempo = 2;
	//wait for the server to sync
	s.sync;
	d = Dictionary.new;
	d.add(\foldernames -> PathName(thisProcess.nowExecutingPath.dirname +/+ "../samples/set1").entries);
	for (0, d[\foldernames].size-1,
		{arg i; d.add(d[\foldernames][i].folderName -> d[\foldernames][i].entries.collect({
			arg sf;
			Buffer.read(s,sf.fullPath);
		});
	)});
	//loads synthdefs from setup folder
	("SynthDefs.scd").loadRelative;
	//loads snippets from setup folder
	("Snippets.scd").loadRelative;
	//wait, for the server to sync
	s.sync;
	//activate StageLimiter - Part of the BatLib quark
	StageLimiter.activate;
	"Setup done!".postln;
};
);
)