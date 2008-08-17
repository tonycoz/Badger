#========================================================================
#
# Badger::Factory
#
# DESCRIPTION
#   Factory module for loading and instantiating other modules.
#
# AUTHOR
#   Andy Wardley   <abw@wardley.org>
#
#========================================================================

package Badger::Factory;

use Badger::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Badger::Prototype Badger::Exporter',
    import    => 'class',
    utils     => 'plural',
#   accessors => 'item items',
    words     => 'ITEM ITEMS ISA',
    constants => 'PKG ARRAY HASH REFS ONCE',
    constant  => {
        FOUND_REF    => 'found_ref',
        BASE_SUFFIX  => '_BASE',
    },
    messages  => {
        no_item => 'No item(s) specified for factory to manage',
        bad_ref => 'Invalid reference for %s factory item %s: %s',
    };

our %LOADED;

sub init {
    my ($self, $config) = @_;
    my $class = $self->class;
    my ($item, $items, $base);

    # 'item' and 'items' can be specified as config params or we look for
    # $ITEM and $ITEMS variables in the current package or those of any 
    # base classes.  NOTE: $ITEM and $ITEMS must be in the same package
    unless ($item = $config->{ item }) {
        foreach my $pkg ($class->heritage) {
            no strict   REFS;
            no warnings ONCE;
            
            if (defined ($item = ${ $pkg.PKG.ITEM })) {
                $items = ${ $pkg.PKG.ITEMS };
                last;
            }
        }
    }
    # TODO: or use $class->id ?
    return $self->error_msg('no_item')
        unless $item;

    # use 'items' in config, or grokked from $ITEMS, or guess plural
    $items = $config->{ items } || $items || plural($item);

    $base = $config->{ base };
    $base = [ $base ] if $base && ref $base ne ARRAY;
    $self->{ base   } = $class->list_vars(uc $item . BASE_SUFFIX, $base);
    $self->{ $items } = $class->hash_vars(uc $items, $config->{ $items });
    $self->{ items  } = $items;
    $self->{ item   } = $item;
    
    return $self;
}

sub base {
    my $self = shift->prototype;
    return @_ 
        ? ($self->{ base } = ref $_[0] eq ARRAY ? shift : [ @_ ])
        :  $self->{ base };
}

sub items {
    my $self  = shift->prototype;
    my $items = $self->{ $self->{ items } };
    if (@_) {
        my $args = ref $_[0] eq HASH ? shift : { @_ };
        @$items{ keys %$args } = values %$args;
    }
    return $items;
}

sub item {
    my $self   = shift->prototype;
    my $type   = shift;
    my $config = $self->params(@_);
    my $items  = $self->{ $self->{ items } };
    
    # massage $type to a canonical form
    my $name  = lc $type;
       $name  =~ s/\W//g;
    my $item  = $items->{ $name };
    my $iref;
    
    # TODO: add $self to $config - but this breaks if %$config check
    # in Badger::Codecs found_ref_ARRAY
    
    if (! defined $item) {
        # we haven't got an entry in the $CODECS table so let's try 
        # autoloading some modules using the $CODEC_BASE
        $item = $self->load($type)
            || return $self->error_msg( not_found => $self->{ item }, $type );
        $item = $item->new($config);
    }
    elsif ($iref = ref $item) {
        my $method 
             = $self->can(FOUND_REF . '_' . $iref)
            || $self->can(FOUND_REF)
            || return $self->error_msg( bad_ref => $self->{ item }, $type, $iref );
            
        $item = $method->($self, $item, $config) 
            || return;
    }
    else {
        # otherwise we load the module and create a new object
        class($item)->load unless $LOADED{ $item }++;
        $item = $item->new($config);
    }

    return $self->found( $name => $item );
#    return $item;
}

sub params {
    my $self   = shift;
    my $params = @_ && ref $_[0] eq HASH ? shift : { @_ };
    $params->{ $self->{ items } } ||= $self;
    return $params;
}

sub load {
    my $self   = shift->prototype;
    my $type   = shift;
    my $bases  = $self->base;
    my @names  = ($type, ucfirst $type, uc $type);   # foo, Foo, FOO
    my $loaded = 0;
    my $module;
    
    foreach my $base (@$bases) {
        foreach my $name (@names) {
            no strict REFS;
            
            # TODO: handle multi-element names, e.g. foo.bar
            
            $module = $base.PKG.$name;
            $self->debug("maybe load $module ?\n") if $DEBUG;
            # Some filesystems are case-insensitive (like Apple's HFS), so an 
            # attempt to load Badger::Example::foo may succeed, when the correct 
            # package name is actually Badger::Codec::Foo
            return $module 
                if ($loaded || class($module)->maybe_load && ++$loaded)
                && @{ $module.PKG.ISA };
        }
    }
    return $self->error_msg( not_found => $self->{ item } => $type );
}

sub found_ref_ARRAY {
    my ($self, $item, $config) = @_;
    
    # default behaviour for handling a factory entry that is an ARRAY
    # reference is to assume that it is a [$module, $class] pair
    
    class($item->[0])->load unless $LOADED{ $item->[0] }++;
    return $item->[1]->new($config);
}

sub found {
    return $_[2];
}


1;