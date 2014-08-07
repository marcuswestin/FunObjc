#import "FunData.h"

double CGPointDistanceSquared(CGPoint pA, CGPoint pB) {
    double dx = pB.x - pA.x;
    double dy = pB.y - pA.y;
    return dx * dx + dy * dy;
}

double CGPointDistance(CGPoint pA, CGPoint pB) {
    return sqrt(CGPointDistanceSquared(pA, pB));
}