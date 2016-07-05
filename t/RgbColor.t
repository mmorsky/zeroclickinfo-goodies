#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use DDG::Test::Goodie;

zci answer_type => "rgb_color";
zci is_cached   => 0;

###################
#  Test Builders  #
###################

my %test_builders = (
    mix    => \&build_answer_mix,
    random => \&build_answer_random,
    reverse => \&build_answer_reverse,
);

my $color_re = qr/^#\p{XDigit}{6}$/i;

sub build_standard_builder {
    my $subtitle_prefix = shift;
    return sub {
        my %params = @_;
        return (
            text_answer => $params{result_color}->{hex},
            data        => {
                subtitle_prefix => $subtitle_prefix,
                %params,
            }
        );
    };
}

sub build_answer_mix {
    build_standard_builder('Mix ')->(@_);
}

sub build_answer_random {
    my %params = @_;
    return (
        text_answer => re($color_re),
        data        => {
            result_color    => superhashof({
                hex => re($color_re)
            }),
            subtitle_prefix => 'Random color between ',
            %params,
        },
    );
}

sub build_answer_reverse {
    build_standard_builder('(RGB) Opposite color of ')->(@_);
}

sub build_structured_answer {
    my ($type, %test_params) = @_;
    my $builder = $test_builders{$type};
    my %answer = $builder->(%test_params);

    return $answer{text_answer},
        structured_answer => {

            data => $answer{data},

            templates => {
                group   => "text",
                options => {
                    title_content    => 'DDH.rgb_color.title_content',
                    subtitle_content => 'DDH.rgb_color.sub_list',
                },
            }
        };
}

sub build_test { test_zci(build_structured_answer(@_)) }

################
#  Test Cases  #
################

my $black = {
    hex  => '#000000',
    name => 'black',
};

my $white = {
    hex  => '#ffffff',
    name => 'white',
};

my $grey = {
    hex  => '#7f7f7f',
    name => '',
};

my $pink = {
    hex  => '#ffc0cb',
    name => 'pink',
};

my $blue = {
    hex  => '#0000ff',
    name => 'blue',
};

my $orange = {
    hex  => '#ffa500',
    name => 'orange',
};

my $bluish_orange = {
    hex  => '#7f527f',
    name => '',
};

my $pinkish_blue = {
    hex  => '#7f60e5',
    name => '',
};

my $yellow = {
    hex  => '#ffff00',
    name => 'yellow',
};

my $tc_mix_black_white = build_test('mix',
    input_colors => [$black, $white],
    result_color => $grey,
);

my $tc_mix_pink_blue = build_test('mix',
    input_colors => [$pink, $blue],
    result_color => $pinkish_blue,
);

my $tc_mix_blue_orange = build_test('mix',
    input_colors => [$blue, $orange],
    result_color => $bluish_orange,
);

my $tc_random_black_white = build_test('random',
    input_colors => [$black, $white],
);

my $tc_random_white_black = build_test('random',
    input_colors => [$white, $black],
);

my $tc_opp_white = build_test('reverse',
    input_colors => [$white],
    result_color => $black,
);

my $tc_opp_blue = build_test('reverse',
    input_colors => [$blue],
    result_color => $yellow,
);

ddg_goodie_test(
    [qw( DDG::Goodie::RgbColor )],
    # Random colors
    'random color' => $tc_random_black_white,
    'rand color'   => $tc_random_black_white,
    # # With bounds
    'random color between white and black' => $tc_random_white_black,
    # # # W/o 'and'
    'random color between black white' => $tc_random_black_white,
    # Using 'colour'
    'random colour' => $tc_random_black_white,
    # Mixing colors
    'mix 000000 ffffff' => $tc_mix_black_white,
    # # With leading '#'
    'mix #000000 #ffffff' => $tc_mix_black_white,
    # # 'and'
    'mix 000000 and ffffff' => $tc_mix_black_white,
    # # Using names
    'mix black and white' => $tc_mix_black_white,
    # Reversing colors
    'opposite of white' => $tc_opp_white,
    # Sample queries (from checking query suggestions)
    'mix pink and blue what color do you get'    => $tc_mix_pink_blue,
    'what do you get if you mix blue and orange' => $tc_mix_blue_orange,
    "what's opposite of blue on the color wheel" => $tc_opp_blue,
    # Invalid queries
    'color'               => undef,
    'color ffffff'        => undef,
    'color picker'        => undef,
    'color picker ffffff' => undef,
    'mix'                 => undef,
    # # From sample queries
    'random color names'                   => undef,
    'mix colors to make black'             => undef,
    'how to mix concrete'                  => undef,
    'blue and gold dress'                  => undef,
    'opposite of blue raining jane lyrics' => undef,
    'pictures of blue rain'                => undef,
    'blue hex color'                       => undef,
    # # With potential to trigger in the future
    'blue and gold' => undef,

);

done_testing;