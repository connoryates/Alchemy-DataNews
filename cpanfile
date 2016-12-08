requires 'perl', '5.008005';

requires 'JSON::XS'    => 3.03;
requires 'Date::Parse' => 2.30;
requires Furl          => 3.09;
requires URI           => 1.71;
requires 'Try::Tiny'   => 2.07;
requires Carp          => 1.38;

on test => sub {
    requires 'Test::More'      => 0.96;
    requires 'Test::Exception' => 0.32;
};
