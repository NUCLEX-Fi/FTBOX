trigger_ff_inst : trigger_ff PORT MAP (
		aclr	 => aclr_sig,
		clock	 => clock_sig,
		data	 => data_sig,
		enable	 => enable_sig,
		q	 => q_sig
	);
