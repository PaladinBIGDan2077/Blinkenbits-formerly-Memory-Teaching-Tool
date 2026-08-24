/* Quartus Prime Version 25.1std.0 Build 1129 10/21/2025 SC Lite Edition */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Ign)
		Device PartName(SOCVHPS) MfrSpec(OpMask(0));
	P ActionCode(Cfg)
		Device PartName(5CSEMA5) Path("C:/QuartusProjects/WordOutput/output_files/") File("word_counter_tester.jic") MfrSpec(OpMask(1) SEC_Device(EPCS128) Child_OpMask(1 3));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
