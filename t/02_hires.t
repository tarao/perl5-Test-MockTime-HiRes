package t::hires;
use parent qw(Test::Class);
use Test::More;
use Test::MockTime::HiRes qw(mock_time);

sub hires : Tests {
    require Time::HiRes;

    subtest 'original' => sub {
        my $now = Time::HiRes::time;
        Time::HiRes::sleep 0.1;
        cmp_ok $now, '<', Time::HiRes::time;
    };

    subtest 'mock' => sub {
        my $now = Time::HiRes::time;

        mock_time {
            is Time::HiRes::time(), $now;
            sleep 1;
            is Time::HiRes::time(), $now + 1;
            Time::HiRes::sleep 1;
            is Time::HiRes::time(), $now + 2;
        } $now;

        cmp_ok Time::HiRes::time() - $now, '<', 2, 'no wait';
    };
}

__PACKAGE__->runtests;
