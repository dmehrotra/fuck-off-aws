
# Fuck off AWS
Amazon publishes a list of the IP addresses they control here: https://ip-ranges.amazonaws.com/ip-ranges.json . What follows is a way to prevent yourself / the websites you visit from reaching out to AWS machines. Spoiler alert: The internet becomes pretty unuseable. 

### Dependencies 
This is for OSX - specifically using their builtin packet filter PF.  You will also need a json processor called JQ.  I used Homebrew to install it
1. `xcode-select --install`
1. `ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
1. `brew install jq`

### Installation
1. Clone this repository 
1. `cd fuck-off-aws/scripts`
1. `chmod +x build.sh start-blocking.sh stop.sh`
1. create or edit the file: `/etc/pf.conf`, and add this line to the end of it: `block out log from any to <aws>`
1. `sudo ./build.sh` <- all scripts must be run as a super user :(.  This sript will find the most recent list of Amazon IPs, and set up a filter using PF to block and log all traffic from your machine to those IP addresses.  This will also block any third party content, images, or fonts that are served by AWS.   

### Usage
1. `sudo ./start-blocking.sh` <- this will enable your packet filter.  It will also log all blocked traffic to an interface, and read those packets using tcpdump.  To log to a file run `sudo start-blocking.sh > log.txt`
1. `sudo ./stop.sh` <- will disable your packet filter.
#### NOTE/BUG
Even when you stop running the start-blocking.sh you will need to run the `sudo ./stop.sh` command to fully disable the filter. 
Also this was adapted from https://github.com/corbanworks/aws-blocker/blob/master/aws-blocker
