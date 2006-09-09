use strict;
use Test::More;
use Class::InsideOut ();
use Scalar::Util qw( refaddr reftype );

$|++; # keep stdout and stderr in order on Win32

my @classes;
BEGIN {
    @classes = qw(
        t::Object::Scalar
        t::Object::Array
        t::Object::Hash
    );
}

eval { require Storable };
if ( $@ ) {
    plan skip_all => "Storable not installed",
}
else
{
    plan tests => 12 * @classes;
}

#--------------------------------------------------------------------------#
# Setup test data
#--------------------------------------------------------------------------#

my %content_for_type = (
    SCALAR  => \do { my $s = 3.14159 },
    ARRAY   => [1, 1, 2, 3, 5, 8 ],
    HASH    => { 1 => 1, 2 => 4, 3 => 9, 4 => 16 },
);

my %names_for_class = (
    "t::Object::Scalar"  => "Larry",
    "t::Object::Array"   => "Moe",
    "t::Object::Hash"    => "Curly",
);

my %custom_prop_for_class = (
    "t::Object::Scalar"  => [ "age", "32" ],
    "t::Object::Array"   => [ "height", "72 inches" ],
    "t::Object::Hash"    => [ "weight", "190 lbs" ],
);

#--------------------------------------------------------------------------#
# tests
#--------------------------------------------------------------------------#

for my $class ( @classes ) {
    require_ok( $class );
    my $o;
    # create the object
    ok( $o = $class->new(),  
        "... Creating $class object"
    );
    
    # note the underlying type
    my $type;
    ok( $type = reftype($o),
        "... Object is reftype $type"
    );
    
    # set a name
    my $name = $names_for_class{ $class };
    $o->name( $name );
    is( $o->name(), $name,
        "... Setting 'name' to '$name'"
    );
    
    # set a class-specific property
    my ( $prop, $val ) = @{ $custom_prop_for_class{ $class } };
    $o->$prop( $val );
    is( $o->$prop(), $val,
        "... Setting custom '$prop' property to $val"
    );
    
    # store class-specific data in the reference
    my $data = $content_for_type{ $type };
    for ( reftype $o ) {
        /SCALAR/ && do { $$o = $$data; last };
        /ARRAY/  && do { @$o = @$data; last };
        /HASH/   && do { %$o = %$data; last };
    }
    pass( "... Loading base $type with data" );

    # freeze object
    my ( $frozen, $thawed );
    ok( $frozen = Storable::freeze( $o ),
        "... Freezing object"
    );

    # thaw object
    ok( $thawed = Storable::thaw( $frozen ),
        "... Thawing object"
    );
    isnt( refaddr $o, refaddr $thawed,
        "... Thawed object is a copy"
    );

    # check name
    is( $thawed->name(), $name,
        "... Property 'name' for thawed object is correct?"
    );

    # set a class-specific property
    is( $thawed->$prop(), $val,
        "... Property '$prop' for thawed objects is correct?"
    );

    # check thawed contents
    is_deeply( $thawed, $data,
        "... Thawed object contents are correct"
    );
};
