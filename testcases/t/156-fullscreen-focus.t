#!perl
# vim:ts=4:sw=4:expandtab
#
# Test if new containers get focused when there is a fullscreen container at
# the time of launching the new one. Also make sure that focusing containers
# in other workspaces work even when there is a fullscreen container.
#
use i3test;

my $i3 = i3(get_socket_path());

my $tmp = fresh_workspace;

################################################################################
# Open the left window.
################################################################################

my $left = open_window({ background_color => '#ff0000' });

is($x->input_focus, $left->id, 'left window focused');

diag("left = " . $left->id);

################################################################################
# Open the right window.
################################################################################

my $right = open_window({ background_color => '#00ff00' });

diag("right = " . $right->id);

################################################################################
# Set the right window to fullscreen.
################################################################################

cmd 'nop setting fullscreen';
cmd 'fullscreen';

################################################################################
# Open a third window. Since we're fullscreen, the window won't be # mapped, so
# don't wait for it to be mapped. Instead, just send the map request and sync
# with i3 to make sure i3 recognizes it.
################################################################################

my $third = open_window({
        background_color => '#0000ff',
        name => 'Third window',
        dont_map => 1,
    });

$third->map;

sync_with_i3;

diag("third = " . $third->id);

################################################################################
# Move the window to a different workspace, and verify that the third window now
# gets focused in the current workspace.
################################################################################

my $tmp2 = get_unused_workspace;

cmd "move workspace $tmp2";

is($x->input_focus, $third->id, 'third window focused');

################################################################################
# Ensure that moving a window to a workspace which has a fullscreen window does
# not focus it (otherwise the user cannot get out of fullscreen mode anymore).
################################################################################

$tmp = fresh_workspace;

my $fullscreen_window = open_window;
cmd 'fullscreen';

my $nodes = get_ws_content($tmp);
is(scalar @$nodes, 1, 'precisely one window');
is($nodes->[0]->{focused}, 1, 'fullscreen window focused');
my $old_id = $nodes->[0]->{id};

$tmp2 = fresh_workspace;
my $move_window = open_window;
cmd "move workspace $tmp";

cmd "workspace $tmp";

$nodes = get_ws_content($tmp);
is(scalar @$nodes, 2, 'precisely two windows');
is($nodes->[0]->{id}, $old_id, 'id unchanged');
is($nodes->[0]->{focused}, 1, 'fullscreen window focused');

################################################################################
# Ensure it's possible to change focus if it doesn't escape the fullscreen
# container with fullscreen global. We can't even focus a container in a
# different workspace.
################################################################################

cmd 'fullscreen';

$tmp = fresh_workspace;
cmd "workspace $tmp";
my $diff_ws = open_window;

$tmp2 = fresh_workspace;
cmd "workspace $tmp2";
cmd 'split h';

$left = open_window;
my $right1 = open_window;
cmd 'split v';
my $right2 = open_window;
$nodes = get_ws_content($tmp);

cmd 'focus parent';
cmd 'fullscreen global';

cmd '[id="' . $right1->id . '"] focus';
is($x->input_focus, $right1->id, 'upper right window focused');

cmd '[id="' . $right2->id . '"] focus';
is($x->input_focus, $right2->id, 'bottom right window focused');

cmd '[id="' . $left->id . '"] focus';
is($x->input_focus, $right2->id, 'prevented focus change to left window');

cmd '[id="' . $diff_ws->id . '"] focus';
is($x->input_focus, $right2->id, 'prevented focus change to different ws');

################################################################################
# Same tests when we're in non-global fullscreen mode. We toggle fullscreen on
# and off to avoid testing whether focus level works in fullscreen for now. It
# should now be possible to focus a container in a different workspace.
################################################################################

cmd 'fullscreen global';
cmd 'fullscreen global';

cmd '[id="' . $right1->id . '"] focus';
is($x->input_focus, $right1->id, 'upper right window focused');

cmd 'focus parent';
cmd 'fullscreen';

cmd '[id="' . $right1->id . '"] focus';
is($x->input_focus, $right1->id, 'upper right window still focused');

cmd '[id="' . $right2->id . '"] focus';
is($x->input_focus, $right2->id, 'bottom right window focused');

cmd '[id="' . $left->id . '"] focus';
is($x->input_focus, $right2->id, 'prevented focus change to left window');

cmd '[id="' . $diff_ws->id . '"] focus';
is($x->input_focus, $diff_ws->id, 'allowed focus change to different ws');

done_testing;
