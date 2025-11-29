pragma circom 2.0.0;
include "circomlib/circuits/comparators.circom";

template TrajectoryCheck() {
    signal input zones[4];
    signal input timestamps[4];
    signal output result;

    var MAX_DURATION = 15;
    var EXPECTED_ZONES[4] = [1, 2, 3, 4];

    component zoneChecks[4];
    for (var i = 0; i < 4; i++) {
        zoneChecks[i] = IsEqual();
        zoneChecks[i].in[0] <== zones[i];
        zoneChecks[i].in[1] <== EXPECTED_ZONES[i];
    }

    component tsChecks[3];
    for (var i = 0; i < 3; i++) {
        tsChecks[i] = LessEqThan(64);
        tsChecks[i].in[0] <== timestamps[i];
        tsChecks[i].in[1] <== timestamps[i + 1];
    }

    signal totalTime;
    totalTime <== timestamps[3] - timestamps[0];

    component timeCheck = LessEqThan(64);
    timeCheck.in[0] <== totalTime;
    timeCheck.in[1] <== MAX_DURATION;

    signal all1;
    signal all2;
    signal all3;
    signal all4;
    signal all5;
    signal all6;
    signal all7;
    signal allPass;

    all1 <== zoneChecks[0].out * zoneChecks[1].out;
    all2 <== zoneChecks[2].out * zoneChecks[3].out;
    all3 <== tsChecks[0].out * tsChecks[1].out;
    all4 <== tsChecks[2].out * timeCheck.out;

    all5 <== all1 * all2;
    all6 <== all3 * all4;
    all7 <== all5 * all6;

    allPass <== all7;

    result <== allPass;
}

component main = TrajectoryCheck();