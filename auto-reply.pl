#!/usr/local/bin perl

require v5.6.12;    # not sure...
require Purple;     # I'm using Pidgin 2.10.6 (libpurple 2.10.6)
require Pidgin;     # TODO: preference panel

use encoding "utf-8";


#####
### Preferences
#
use constant {
    MAX_REPLY_NUM => 5,
    REPLY_DELAY_SECOND => 5
};

our %INFO = (
    last_senders => {}, # {$count, $time, $is_new}
    reply_message => '<font color="#4b3dca" face="Ubuntu" size="2">and then?</font>'
);

sub reset_info
{
    %{$INFO{last_senders}} = {};
    Purple::Debug::info($PLUGIN_INFO{name}, "RESET\n");
}


#####
### Plugin Initializations
#
our %PLUGIN_INFO = (
    perl_api_version => 2,
    name => "Auto-Reply Fun",
    version => "1.0.0",
    summary => "Have fun!",
    description => "Auto-reply according to the received message.",
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
    my $plugin = shift;

    Purple::Debug::info($PLUGIN_INFO{name}, "loaded\n");

    ## Conversations Hook
    $conv = Purple::Conversations::get_handle();
    Purple::Signal::connect($conv, "received-im-msg", $plugin,
                            \&conv_received_msg, "IM");
}

sub plugin_unload
{
    my $plugin = shift;

    Purple::Debug::info($PLUGIN_INFO{name}, "unloaded\n");
}

#####
### Conversations
#
sub conv_received_msg
{
	my ($account, $sender, $message, $conv, $flags, $data) = @_;

	Purple::Debug::misc("REC[$data]", $account->get_username() . " <-- $sender, $message, $flags)\n");

    if ( $data eq "IM" and $conv) {
        my $im = $conv->get_im_data();
        # online | busy | away | hidden
        my $my_status = $account->get_active_status()->get_id();

        if ( $my_status eq "away" ) {
            auto_reply($im, $sender);
        } else {
            reset_info();
        }
    }
}

sub auto_reply
{
    my ($im, $sender) = @_;

    unless ( exists $INFO{last_senders}{$sender} ) {
        %{$INFO{last_senders}{$sender}} = (
            count => 0,
            time => 0,
            is_new => 1
        );
    }

    my ($count, $time, $is_new) = (
        \$INFO{last_senders}{$sender}{count},
        \$INFO{last_senders}{$sender}{time},
        \$INFO{last_senders}{$sender}{is_new} );

    Purple::Debug::misc($PLUGIN_INFO{name},
                        "auto-replying...times: " . ${$count} . "\n");

    if ( MAX_REPLY_NUM > ${$count} ) {
        if ( ${$is_new} or time - ${$time} >= REPLY_DELAY_SECOND ) {
            ${$is_new} = 0;
            ${$count}++;
            ${$time} = time;
            reply($im);
        }
    }
}

sub reply
{
    my $im = shift;

    $im->send($INFO{reply_message});
}
