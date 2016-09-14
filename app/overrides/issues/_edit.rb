Deface::Override.new :virtual_path  => 'issues/_edit',
                     :name          => 'privates_notes_default',
                     :original		=> '2309a6061eae06cfacfa252740ea05a854bf6258',
                     :replace       => "erb[loud]:contains(\"f.check_box :private_notes, :no_label => true\")",
                     :text          => '<%= f.check_box :private_notes, :no_label => true, checked: true %>'