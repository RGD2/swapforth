\ #include sb.fs on a 'sudo make clean bootstrap j4a' image.
\ must be done after each reboot.
\ must never reboot / lose power whilst hydrualics is on!
\ workaround for image rebuilding being broken
new : .xt .x ; \ more space
#include j4a-maxrefdes24.fs
#include mrc-samples.fs
ini

