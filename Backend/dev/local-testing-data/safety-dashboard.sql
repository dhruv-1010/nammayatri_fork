INSERT INTO atlas_safety_dashboard.person (id, first_name, last_name,email_encrypted, email_hash, mobile_number_encrypted, mobile_number_hash, mobile_country_code, password_hash, created_at, updated_at) VALUES
	('3680f4b5-dce4-4d03-aa8c-5405690e87bd', 'police_admin', 'police_admin', '0.1.0|0|LhbMPLXsyXE0tjkVpk2AsylStET+zn3gLufYYvF+mWEGaXojqY71IUsw/gJWIIWzbQTGsY31FlnT3BL8o360B2kngyHgMg9A3Jnj0I4=', '\xef2654345b65cbe5230f3cc47ff26ff73cfd7023e10ac258b4b88bab8221a181', '0.1.0|0|oJOzop+9gdchzwbhz/EyxkSZ7s4z/irFEpsQrsNmSXbKnfe96m+P9xkFqy8/BFU1sGUhgszM1JKsuJNXBQ==', '\x26d21f3ddcce96b1fab220d6aea0b5341d4653e812d4e18d542577acbdeef640', '+91',	'\x8c03a02fbcb46d7f7624063574892f64f19b9871138edfcfeb4f0361362e567f', '2022-09-06 11:25:42.609155+00', '2022-09-06 11:25:42.609155+00');

INSERT INTO atlas_safety_dashboard.registration_token (id, token, person_id, created_at) VALUES
	('b856907d-9fb3-4804-9ae4-a53ca902ea0d', '0f3378e2-da5b-4eac-a0f6-397ca48358de', '3680f4b5-dce4-4d03-aa8c-5405690e87bd', now ());
