package Test::MockTime::HiRes;
use strict;
use warnings;

# cpan
use Test::More;
use Test::MockTime qw(:all);
use Time::HiRes;

# core
use Exporter qw(import);
our @EXPORT = qw(
    set_relative_time
    set_absolute_time
    set_fixed_time
    restore_time
    mock_time
);

my $datetime_was_loaded;

BEGIN {
    no warnings 'redefine';
    my $_time_original = \&Test::MockTime::_time;
    *Test::MockTime::_time = sub {
        my ($time, $spec) = @_;
        my $usec = 0;
        ($time, $usec) = ($1, $2) if $time =~ /\A(\d+)[.](\d+)\z/;
        $time = $_time_original->($time, $spec);
        $time = "$time.$usec" if $usec;
        return $time;
    };
    my $time_original = \&Test::MockTime::time;
    *Test::MockTime::time = sub () {
        return int($time_original->());
    };
    *CORE::GLOBAL::time = \&Test::MockTime::time;

    *CORE::GLOBAL::sleep = sub ($) {
        return int(Test::MockTime::HiRes::_sleep($_[0], \&CORE::sleep));
    };
    my $hires_clock_gettime = \&Time::HiRes::clock_gettime;
    my $hires_time = \&Time::HiRes::time;
    my $hires_sleep = \&Time::HiRes::sleep;
    my $hires_usleep = \&Time::HiRes::usleep;
    my $hires_nanosleep = \&Time::HiRes::nanosleep;
    *Time::HiRes::clock_gettime = sub (;$) {
        return Test::MockTime::HiRes::time($hires_clock_gettime, @_);
    };
    *Time::HiRes::time = sub () {
        return Test::MockTime::HiRes::time($hires_time);
    };
    *Time::HiRes::sleep = sub (;@) {
        return Test::MockTime::HiRes::_sleep($_[0], $hires_sleep);
    };
    *Time::HiRes::usleep = sub ($) {
        return Test::MockTime::HiRes::_sleep($_[0], $hires_usleep, 1000);
    };
    *Time::HiRes::nanosleep = sub ($) {
        return Test::MockTime::HiRes::_sleep($_[0], $hires_nanosleep, 1000_000);
    };

    $datetime_was_loaded = 1 if $INC{'DateTime.pm'};
}

sub time (&;@) {
    my $original = shift;
    $Test::MockTime::fixed // $original->(@_) + $Test::MockTime::offset;
}

sub _sleep ($&;$) {
    my ($sec, $original, $resolution) = @_;
    if (defined $Test::MockTime::fixed) {
        $sec /= $resolution if $resolution;
        $Test::MockTime::fixed += $sec;
        note "sleep $sec";
        return $sec;
    } else {
        return $original->($sec);
    }
}

sub mock_time (&$) {
    my ($code, $time) = @_;

    warn sprintf(
        '%s does not affect DateTime->now since %s is loaded after DateTime',
        'mock_time',
        __PACKAGE__,
    ) if $datetime_was_loaded;

    local $Test::MockTime::fixed = $time;
    return $code->();
}

1;
__END__
