requires 'Test::MockTime';
requires 'Time::HiRes';
requires 'Test::More';

on test => sub {
    requires 'Test::Base';
    requires 'Test::Class';
    requires 'Test::Requires';
    suggests 'AnyEvent';
};
