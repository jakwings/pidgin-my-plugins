#!/usr/local/bin perl

require v5.6.12;    # not sure...
require Purple;     # I'm using Pidgin 2.10.6 (libpurple 2.10.6)

use encoding "utf-8";

use constant {
    TRUE => 1,
    FLASE => 0
};


#####
### Pereferences
#
my %FONT = (
    face => "Ubuntu",
    size => 2,
    color => "#4b3dca"
);


#####
### Plugin Initializations
#
our %PLUGIN_INFO = (
    perl_api_version => 2,
    name => "EXEC command",
    version => "1.0.0",
    summary => "Run commands and get the output.",
    description => "/exec [-o] <command>",
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

    my $plugin = shift;
    my $conv = Purple::Conversations::get_handle();

    Purple::Cmd::register($plugin, "exec", "s",
        Purple::Cmd::Priority::DEFAULT,
        Purple::Cmd::Flag::IM | Purple::Cmd::Flag::CHAT, undef,
        \&exec_command, "/exec [-o] &lt;command&gt;", "exec");
}

sub plugin_unload
{
    dbmsg("unloaded");
}


#####
### Basic
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

sub trim
{
    my $str = shift;

    $str =~ s/(?:^\s+|\s+$)//g;
    return $str;
}


#####
### Functions
#
sub format_output
{
    my $output = shift;
    my $font_face = $FONT{face};
    my $font_size = $FONT{size};
    my $font_color = $FONT{color};

    $output =~ s/\&/&amp;/g;
    $output =~ s/\</&lt;/g;
    $output =~ s/\>/&gt;/g;
    return "<font color=\"$font_color\" face=\"$font_face\" size=\"$font_size\">$output</font>";
}

sub send_output
{
    my ($type, $conv, $output, $to_buddy) = @_;

    if ( Purple::Conversation::Type::IM == $type ) {
        if ( $to_buddy ) {
            $conv->get_im_data()->send(format_output($output));
        } else {
            $conv->get_im_data()->write("/exec", $output,
                Purple::Conversation::Flags::NO_LOG |
                Purple::Conversation::Flags::RAW |
                Purple::Conversation::Flags::SYSTEM
                , time);
        }
        return TRUE;
    }
    if ( Purple::Conversation::Type::CHAT == $type ) {
        if ( $to_buddy ) {
            $conv->get_chat_data()->send(format_output($output));
        } else {
            $conv->get_chat_data()->write("/exec", $output,
                Purple::Conversation::Flags::NO_LOG |
                Purple::Conversation::Flags::RAW |
                Purple::Conversation::Flags::SYSTEM
                , time);
        }
        return TRUE;
    }
    return FALSE;
}

sub exec_command
{
    my ($conv, $cmd_name, @args, @error) = @_;
    my $type = $conv->get_type();
    my $arg = trim($args[1]);

    if ( substr($arg, 0, 3) eq "-o " ) {
        my $command = substr $arg, 3;
        my $output = `$command`;

        chomp $output;
        unless ( send_output($type, $conv, $output, TRUE) ) {
            return Purple::Cmd::Return::FAILED;
        }
    } else {
        my $command = trim($arg);
        my $output = `$command`;

        chomp $output;
        unless ( send_output($type, $conv, $output, FALSE) ) {
            return Purple::Cmd::Return::FAILED;
        }
    }
    return Purple::Cmd::Return::OK;
}
