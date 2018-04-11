#!/usr/bin/perl
#
# Simply for easily storing data
#
# @File ircnotesdata.pl
# @Author DreamHealer aka Pintuz
# @Created Apr 9, 2018 4:23:00 PM
#

package IRCNotesData;                                                                                                                                                                                   
use strict;                                                                                                                                                                                               
use warnings;                                                                                                                                                                                             
                                                                                                                                                                                                          
sub new {                                                                                                                                                                                                 
    my $class = shift;                                                                                                                                                                                    
    my $self = { @_ };                                                                                                                                                                                    
    bless ( $self );                                                                                                                                                                                      
    return $self;                                                                                                                                                                                         
}                                                                                                                                                                                                         

1;