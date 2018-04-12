#!/usr/bin/perl
#
# Irssi script to easily add notes regarding events in an actual database 
# and retrieve the information for later use.
#
# Installation notes:
#
#   Install DBI
#
#   Place files under ~/.irssi/scripts so it looks this way:
#   
#      ~/.irssi/scripts/ircnotes.pl
#      ~/.irssi/scripts/ircnotes/ircnotesdata.pl
#
#   Create a database in your mysql server and grant privileges to it:
#
#      CREATE database ircnotes;
#      GRANT ALL PRIVILEGES ON ircnotes.* to 'user'@'localhost' IDENTIFIED BY 'userpass';
#
#   Make sure database settings section down below is using accurate values
#
#   Load it in your Irssi:
#   
#      /script load ircnotes
#
#   Script will automagically create the table neccessary for the script
#   if it cant find it in the database you pointed it to.
#
# Commands:
#
#   IRCNOTES HELP <command>
#   IRCNOTES SEARCH <string>
#   IRCNOTES ADD <nick|chan|thing> <comment>
#   IRCNOTES DEL <id>
#
# @File ircnotes.pl
# @Author DreamHealer aka Pintuz
# @Created Apr 9, 2018 4:06:07 PM
#

use strict;
use warnings;
use DBI;

use Irssi;
require 'ircnotes/ircnotesdata.pl';

my $setting = new IRCNotesData (
    authors     => 'DreamHealer',
    contact     => 'dreamhealer@avade.net',
    name        => 'ircnotes',
    version     => '0.0.8',
    description => 'This script will aid an user in keeping track of nick,chan ' .
                   'for later use ',
    license     => 'Public Domain',
);

# Connect to the database.
my $dbname = "ircnotes";
my $dbhost = "10.0.1.41";
my $dbuser = "ircnotes";
my $dbpass = "ircnotes";
my $dbh;
                
Irssi::theme_register ( ['ircnotes_loaded', '%R>>>%n %_Scriptinfo:%_ Loaded $0 version $1 by $2.' ] );
Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'ircnotes_loaded', $setting->{name}, $setting->{version}, $setting->{authors});

# Connect to database
sub dbconnect {
    $dbh = DBI->connect ( "DBI:mysql:database=".$dbname.";host=".$dbhost, $dbuser, $dbpass, { 'RaiseError' => 1 } );
    if ( defined $dbh ) {
        return 1;
    } else {
        return 0;
    }
}
                
# Disconnect from database
sub dbdisconnect {
    if ( defined $dbh ) {
        $dbh->disconnect ( );
    }
}

if ( tablesExist ( ) eq 1 ) {
    print ( "[IRCNotes] Found database tables." );
} elsif ( init ( ) ) {
    print ( "[IRCNotes] Successfully created database tables." );
} else {
    print ( "[IRCNotes] Database error." );
}


# FILTER INCOMING
sub filterText {
    my ( $text ) = @_;
    my $win = Irssi::active_win ( );
    my $target;

    my @words = split / /, $text;

    if ( uc $words[0] eq "IRCNOTES" ) {

        if ( ! defined $words[1] || uc $words[1] eq "HELP" ) {

            if ( ! defined $words[2] ) {
                printToWin ( $win, "*** HELP ***" );
                printToWin ( $win, "Commands:" );
                printToWin ( $win, "   %WHELP%n             - Shows this help information" );
                printToWin ( $win, "   %WHELP <command>%n   - Shows help for a specific command" );
                printToWin ( $win, "   %WSEARCH%n           - Search notes for name, text or date string" );
                printToWin ( $win, "   %WADD%n              - Adds a note" );
                printToWin ( $win, "   %WDEL%n              - Deletes a note" );
                printToWin ( $win, "   %WUPDATE%n           - Updates a note" );
                printToWin ( $win, "*** End ***" );

            } elsif ( uc $words[2] eq "HELP" ) {
                printToWin ( $win, "Hah!.. you funny! ;)" );

            } elsif ( uc $words[2] eq "SEARCH" ) {
                printToWin ( $win, "*** HELP SEARCH ***" );
                printToWin ( $win, "Syntax: %WIRCNOTES SEARCH <string>" );
                printToWin ( $win, "Ex: ircnotes search dreamhealer" );
                printToWin ( $win, "    ircnotes search #cocacola" );
                printToWin ( $win, "    ircnotes search 2018-04-01" );
                printToWin ( $win, "*** End ***" );

            } elsif ( uc $words[2] eq "ADD" ) {
                printToWin ( $win, "*** HELP ADD ***" );
                printToWin ( $win, "Syntax: %WIRCNOTES ADD <name> <string>" );
                printToWin ( $win, "Ex: ircnotes add dreamhealer ~user\@some.leet.host was found massinviting in #cocacola for #dreamhealer" );
                printToWin ( $win, "    ircnotes add #cocacola got flooded, sorted it" );
                printToWin ( $win, "    ircnotes add fire.avade.net found desynched again, slapped it around abit with a large trout" );
                printToWin ( $win, "*** End ***" );

            } elsif ( uc $words[2] eq "DEL" ) {
                printToWin ( $win, "*** HELP DEL ***" );
                printToWin ( $win, "Syntax: %WIRCNOTES DEL <id>" );
                printToWin ( $win, "Ex: ircnotes del 10" );
                printToWin ( $win, "*** End ***" );
                
            } elsif ( uc $words[2] eq "UPDATE" ) {
                printToWin ( $win, "*** HELP UPDATE ***" );
                printToWin ( $win, "Syntax: %WIRCNOTES UPDATE <id|last>" );
                printToWin ( $win, "Ex: ircnotes update 10 DreamHealer ~user\@some.leet.host was found flooding in #cocacola" );
                printToWin ( $win, "    ircnotes update LAST DreamHealer ~user\@some.leet.host was found loading clones in #cocacola" );
                printToWin ( $win, "*** End ***" );
            }
            Irssi::signal_stop ( );

        } elsif ( uc $words[1] eq "SEARCH" ) {
            if ( ! defined $words[2] ) {
                printToWin ( $win, "Syntax: %WIRCNOTES SEARCH <string>" );

            } else {
                my @logs = doSearch ( $words[2] );
                printToWin ( $win, "*** SEARCH: ".$words[2]." ***" );
                foreach my $log ( @logs ) {
                    printToWin ( $win, "%W[".$log->{id}."]%n ".$log->{stamp}.": %W".$log->{name}."%n - ".$log->{comment} );
                }
                printToWin ( $win, "*** End ***" );
            }
            Irssi::signal_stop ( );

        } elsif ( uc $words[1] eq "ADD" ) {
            if ( ! defined $words[3] ) {
                printToWin ( $win, "Syntax: %WIRCNOTES ADD <name> <note>" );

            } else {
                my $num = ( scalar @words ) - 1;
                my @cText = splice @words, 3, $num;
                my $comment = join ' ', @cText;

                if ( doAdd ( $words[2], $comment ) eq 1 ) {
                    printToWin ( $win, "Comment successfully saved!." );
                } else {
                    printToWin ( $win, "Comment %WFAILED%n to be saved!." );
                }
            }
            Irssi::signal_stop ( );

        } elsif ( uc $words[1] eq "UPDATE" ) {
            my $id;
            
            if ( ! defined $words[4] ) {
                printToWin ( $win, "Syntax: %WIRCNOTES UPDATE <id|LAST> <name> <note>" );
		
	    } elsif ( ( $id = getUpdateID ( $words[2] ) ) == -1 ) {
		printToWin ( $win, "Error: No such note found." );

            } else {
                my $num = ( scalar @words ) - 1;
                my @cText = splice @words, 4, $num;
                my $comment = join ' ', @cText;
                my $res = doUpdate ( $id, $words[3], $comment );
                
                if ( $res eq -1 ) {
                    printToWin ( $win, "Comment ".$words[2]." not found!." );
                } elsif ( $res eq 1 ) {
                    printToWin ( $win, "Comment successfully updated!." );
                } else {
                    printToWin ( $win, "Comment %WFAILED%n to be updated!." );
                }
            }
            Irssi::signal_stop ( );

        } elsif ( uc $words[1] eq "DEL" ) {
            if ( ! defined $words[2] ) {
                printToWin ( $win, "Syntax: %WIRCNOTES DEL <id>" );

            } else {
                if ( doDel ( $words[2] ) eq 1 ) {
                    printToWin ( $win, "Comment successfully removed!." );
                } else {
                    printToWin ( $win, "Comment %WFAILED%n to be removed!." );
                }
            }
            Irssi::signal_stop ( );
        }
    }
}


###################
### SUBROUTINES ###
###################

# Print
sub printToWin {
    my ( $win, $text ) = @_;
    $win->print ( "[IRCNotes]> ".$text, MSGLEVEL_CLIENTCRAP );
}

# Search
sub doSearch {
    my ( $word ) = @_;
    my $sth;
    my @logs;
    $word =~ s/\*/\%/g;

    my $query = << "EOS";
select id, name, comment, stamp
from comment
where
name like ?
or ( comment like ?
     or stamp like ? )
order by stamp asc
EOS
;

    if ( dbconnect ( ) eq 1 ) {
        eval {
            my $wild = "%".$word."%";
            $sth = $dbh->prepare ( $query ) or die "Cant prepare: ".$dbh->errstr;
            $sth->bind_param ( 1, $wild );
            $sth->bind_param ( 2, $wild );
            $sth->bind_param ( 3, $wild );
            $sth->execute ( ) or die "Cant execute: ".$dbh->errstr;
            while ( my $log = $sth->fetchrow_hashref ( ) ) {
                push ( @logs, $log );
            }
        };

        if ( $@ ) {
            print STDERR "ERROR: $@\n";
        } else {
            $sth->finish ( );
        }
        dbdisconnect ( );

    } else {
        print ( "Error: no db connection found." );
    }
    return @logs;
}

sub getLastID {
    my $sth;
    my $id;
    
    my $query = << "EOS";
select id
from comment
order by id desc
limit 1
EOS
;

    if ( dbconnect ( ) eq 1 ) {
        eval {
            $sth = $dbh->prepare ( $query ) or die "Cant prepare: ".$dbh->errstr;
            $sth->execute ( ) or die "Cant execute: ".$dbh->errstr;
            if ( my $note = $sth->fetchrow_hashref ( ) ) {
                $id = $note->{id};
            } else {
                undef $id;
            }
        };

        if ( $@ ) {
            print STDERR "ERROR: $@\n";
        } else {
            $sth->finish ( );
        }
        dbdisconnect ( );
    } else {
        print ( "Error: no db connection found." );
    }
    
    if ( ! defined $id ) {
        return -1;
    } else {
        return $id;
    }
}

# getUpdateID
sub getUpdateID {
    my ( $id ) = @_;
    my $sth;
    
    if ( uc $id eq "LAST" ) {
        return getLastID ( );
    }

    my $query = << "EOS";
select id 
from comment
where
id = ?
EOS
;

    if ( dbconnect ( ) eq 1 ) {
        eval { 
            $sth = $dbh->prepare ( $query ) or die "Cant prepare: ".$dbh->errstr;
            $sth->bind_param ( 1, $id );
            $sth->execute ( ) or die "Cant execute: ".$dbh->errstr;
            if ( my $note = $sth->fetchrow_hashref ( ) ) {
                $id = $note->{id};
            } else {
                undef $id;
            }
        };

        if ( $@ ) {
            print STDERR "ERROR: $@\n";
        } else {
            $sth->finish ( );
        }
        dbdisconnect ( );

    } else {
        print ( "Error: no db connection found." );
    }
    
    if ( ! defined $id ) {
        return -1;
    } else {
        return $id;
    }
}

# Add
sub doAdd {
    my ( $name, $comment ) = @_;
    my $sth;
    my $query = << "EOS";
insert into comment
( name, comment, stamp )
values ( ?, ?, NOW() )
EOS
;

    if ( dbconnect ( ) eq 1 ) {
        eval {
            $sth = $dbh->prepare ( $query ) or die "Cant prepare: ".$dbh->errstr;
            $sth->bind_param ( 1, $name );
            $sth->bind_param ( 2, $comment );
            $sth->execute ( ) or die "Cant execute: ".$dbh->errstr;
        };

        if ( $@ ) {
            print STDERR "ERROR: $@\n";
            dbdisconnect ( );
            return 0;
        } else {
            $sth->finish ( );
            dbdisconnect ( );
            return 1;
        }

    } else {
        print ( "Error: no db connection found." );
        return 0;
    }
}

# Update
sub doUpdate {
    my ( $id, $name, $comment ) = @_;
    my $sth;
    my $query = << "EOS";
update comment 
set name = ?, comment = ? 
where id = ? 
EOS
;

    if ( dbconnect ( ) eq 1 ) {
        eval {
            $sth = $dbh->prepare ( $query ) or die "Cant prepare: ".$dbh->errstr;
            $sth->bind_param ( 1, $name );
            $sth->bind_param ( 2, $comment );
            $sth->bind_param ( 3, $id );
            $sth->execute ( ) or die "Cant execute: ".$dbh->errstr;
        };

        if ( $@ ) {
            print STDERR "ERROR: $@\n";
            dbdisconnect ( );
            return 0;
        } else {
            $sth->finish ( );
            dbdisconnect ( );
            return 1;
        }

    } else {
        print ( "Error: no db connection found." );
        return 0;
    }
}

# Del
sub doDel {
    my ( $id ) = @_;
    my $sth;

    if ( ! ( $id =~ /^[0-9,.E]+$/ ) ) {
        return 0;
    }

    my $query = << "EOS";
delete from comment
where id = ?
EOS
;

    if ( dbconnect ( ) eq 1 ) {
        eval {
            $sth = $dbh->prepare ( $query ) or die "Cant prepare: ".$dbh->errstr;
            $sth->bind_param ( 1, $id );
            $sth->execute ( ) or die "Cant execute: ".$dbh->errstr;
        };

        if ( $@ ) {
            print STDERR "ERROR: $@\n";
            dbdisconnect ( );
            return 0;
        } else {
            $sth->finish ( );
            dbdisconnect ( );
            return 1;
        }

    } else {
        print ( "Error: no db connection found." );
        return 0;
    }
}

# Init
sub init {
    my $sth;
    my $query = << "EOS";
    CREATE TABLE comment (
      id int(11) NOT NULL AUTO_INCREMENT,
      name varchar(32) DEFAULT NULL,
      comment varchar(256) DEFAULT NULL,
      stamp datetime DEFAULT NULL,
      PRIMARY KEY (id)
    ) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=latin1
EOS
;

    if ( dbconnect ( ) eq 1 ) {
        eval {
            $sth = $dbh->prepare ( $query ) or die "Cant prepare: ".$dbh->errstr;
            $sth->execute ( ) or die "Cant execute: ".$dbh->errstr;
        };

        if ( $@ ) {
            print STDERR "ERROR: $@\n";
            dbdisconnect ( );
            return 0;
        } else {
            $sth->finish ( );
            dbdisconnect ( );
            return 1;
        }

    } else {
        print ( "Error: no db connection found." );
        return 0;
    }
}

# TablesExist
sub tablesExist {
    my $sth;
    my $query = << "EOS";
    desc comment
EOS
;

    if ( dbconnect ( ) eq 1 ) {
        eval {
            $sth = $dbh->prepare ( $query ) or die "Cant prepare: ".$dbh->errstr;
            $sth->execute ( ) or die "Cant execute: ".$dbh->errstr;
        };

        if ( $@ ) {
            print STDERR "ERROR: $@\n";
            dbdisconnect ( );
            return 0;
        } else {
            $sth->finish ( );
            dbdisconnect ( );
            return 1;
        } 

    } else {
        print ( "Error: no db connection found." );
        return 0;
    }
}

##################
### Signal Add ###
##################
Irssi::signal_add ( "send text", "filterText" );
