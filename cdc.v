/*
    Let's say a signal from clkA domain is needed in clkB domain. It needs to be "synchronized" to clkB domain, so we want to build a synchronizer design, which takes a signal from clkA domain, and creates a new signal into clkB domain.
    In this first design, we assume that the "Signal-in" changes slowly compared to both clkA and clkB clock speeds.
    All you need to do is to use two flip-flops to move the signal from clkA to clkB (to learn why, get back to the links).
*/
module Signal_CrossDomain(
    input clkA,   // we actually don't need clkA in that example, but it is here for completeness as we'll need it in further examples
    input SignalIn_clkA,
    input clkB,
    output SignalOut_clkB
);

    // We use a two-stages shift-register to synchronize SignalIn_clkA to the clkB clock domain
    reg [1:0] SyncA_clkB;
    always @(posedge clkB) SyncA_clkB[0] <= SignalIn_clkA;   // notice that we use clkB
    always @(posedge clkB) SyncA_clkB[1] <= SyncA_clkB[0];   // notice that we use clkB

    assign SignalOut_clkB = SyncA_clkB[1];  // new signal synchronized to (=ready to be used in) clkB domain
endmodule


/*
    A flag to another clock domain
    If the signal that needs to cross the clock domains is just a pulse (i.e. it lasts just one clock cycle), we call it a "flag". The previous design usually doesn't work (the flag might be missed, or be seen for too long, depending on the ratio of the clocks used).
    We still want to use a synchronizer, but one that works for flags.
*/
module Flag_CrossDomain(
    input clkA,
    input FlagIn_clkA,   // this is a one-clock pulse from the clkA domain
    input clkB,
    output FlagOut_clkB   // from which we generate a one-clock pulse in clkB domain
);

    reg FlagToggle_clkA;
    always @(posedge clkA) FlagToggle_clkA <= FlagToggle_clkA ^ FlagIn_clkA;  // when flag is asserted, this signal toggles (clkA domain)

    reg [2:0] SyncA_clkB;
    always @(posedge clkB) SyncA_clkB <= {SyncA_clkB[1:0], FlagToggle_clkA};  // now we cross the clock domains

    assign FlagOut_clkB = (SyncA_clkB[2] ^ SyncA_clkB[1]);  // and create the clkB flag
endmodule