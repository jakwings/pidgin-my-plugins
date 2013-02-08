#!/usr/local/bin perl

require v5.6.12;    # not sure...
require Purple;     # I'm using Pidgin 2.10.6 (libpurple 2.10.6)
#require Pidgin;     # TODO: preference panel

use encoding "utf-8";


#####
### Preferences
#
our @NICK_NAMES = ("John", "J.M");


#####
### Plugin Initializations
#
our %PLUGIN_INFO = (
    perl_api_version => 2,
    name => "Chatroom At-Me Notifier",
    version => "1.1.0",
    summary => "Notify if someone @ you!",
    description => "Notify and show what others said.",
    author => "Jak Wings <jakwings\@gmail.com>",
    url => "http://likelikeslike.com",
    load => "plugin_load",
    unload => "plugin_unload"
);

sub plugin_init
{
    return %PLUGIN_INFO;
}

sub plugin_load
{
    dbmsg("loaded");

    my $conv = Purple::Conversations::get_handle();
    my $plugin = shift;

    ## Conversations Hook
    Purple::Signal::connect($conv, "received-chat-msg", $plugin,
                            \&conv_received_msg, "CHAT");
}

sub plugin_unload
{
    dbmsg("unloaded");
}


#####
### Basic Functions
#
sub dbmsg
{
    my $msg = shift;
    my $is_misc = shift;

    chomp($msg);
    if ( $is_misc ) {
        Purple::Debug::misc($PLUGIN_INFO{name}, "$msg\n");
    } else {
        Purple::Debug::info($PLUGIN_INFO{name}, "$msg\n");
    }
}


#####
### Conversations
#
sub conv_received_msg
{
	my ($account, $sender, $message, $conv, $flags, $data) = @_;

	dbmsg("REC[$data]: " . $account->get_username() . " <-- $sender, $message, $flags", 1);

    if ( $data eq "CHAT" ) {
        foreach $name (@NICK_NAMES) {
            $message =~ s/<[^>]+>//g;
            if ( $message =~ /${name}/i ) {
                notify($account, $conv->get_title(), $sender, $message);
                break;
            }
        }
    }
}

sub notify
{
    my ($account, $chatroom, $sender, $message) = @_;
    my $conv = Purple::Conversation->new(1, $account, "\@ you!");

    $conv->get_im_data()->write("${chatroom} - ${sender}", $message, 0x2 | 0x1000, time);
}
