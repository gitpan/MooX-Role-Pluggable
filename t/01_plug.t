use Test::More tests => 9;
use strict; use warnings FATAL => 'all';

{
  package
    MyDispatcher;
  use Test::More;
  use Moo;
  use MooX::Role::Pluggable::Constants;
  with 'MooX::Role::Pluggable';

  sub process {
    my ($self, $event, @args) = @_;
    my $retval = $self->_pluggable_process( 'PROCESS', $event, \@args );
  }

  sub shutdown {
    my ($self) = @_;
    $self->_pluggable_destroy;
  }

  sub do_test_events {
    my ($self) = @_;
    $self->process( 'test' );
  }

  around '_pluggable_event' => sub {
    my ($orig, $self) = splice @_, 0, 2;
    $self->process( @_ )
  };

  sub P_test {
    pass( __PACKAGE__ . ' P_test' );
    EAT_NONE
  }
}

{
  package
    MyPlugin;
  use strict; use warnings FATAL => 'all';
  use Test::More;

  use MooX::Role::Pluggable::Constants;

  sub new { bless [], shift }

  sub plugin_register {
    my ($self, $core) = splice @_, 0, 2;
    pass( __PACKAGE__ . ' plug registered' );
    $core->subscribe( $self, 'PROCESS', 'all' );
    EAT_NONE
  }

  sub plugin_unregister {
    pass( "Plugin unregistered" );
  }

  sub P_test {
    my ($self, $core) = splice @_, 0, 2;
    pass( "Plugin got P_test" );
    EAT_NONE
  }

  sub other_register {
    my ($self, $core) = splice @_, 0, 2;
    pass( "Got other_register" );
    $core->subscribe( $self, 'PROCESS', 'all' );
    EAT_NONE
  }
  sub other_unregister { EAT_NONE }

  sub Process_test {
    pass( "Got Process_test" );
  }
}

my $disp = MyDispatcher->new;

ok( $disp->does('MooX::Role::Pluggable'), 'Class does Role' );

ok( $disp->plugin_add( 'MyPlug', MyPlugin->new ), 'plugin_add()' );

$disp->do_test_events;

$disp->shutdown;

ok( $disp->_pluggable_init(
  types => { PROCESS => "Process" },
  reg_prefix => 'other_',
), '_pluggable_init()' );
$disp->plugin_add( 'MyPlugB', MyPlugin->new );
$disp->process('test');
