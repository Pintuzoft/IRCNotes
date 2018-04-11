IRCNotes

Irssi script to easily add notes regarding events in an actual database 
and retrieve the information for later use.

Installation notes:

   Install DBI

   Place files under ~/.irssi/scripts so it looks this way:
   
      ~/.irssi/scripts/ircnotes.pl
      ~/1.irssi/scripts/ircnotes/ircnotesdata.pl

   Create a database in your mysql server and grant privileges to it:

      CREATE database ircnotes;
      GRANT ALL PRIVILEGES ON ircnotes.* to 'user'@'localhost' IDENTIFIED BY 'userpass';

   Make sure database settings section down below is using accurate values

   Load it in your Irssi:
   
      /script load ircnotes

   Script will automagically create the table neccessary for the script
   if it cant find it in the database you pointed it to.

Commands:

   IRCNOTES HELP <command>
   IRCNOTES SEARCH <string>
   IRCNOTES ADD <nick|chan|thing> <comment>
   IRCNOTES DEL <id>
