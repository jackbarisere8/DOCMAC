import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/docmac_iconly.dart';

class ContactCountry {
  const ContactCountry(this.name, this.code, this.flag, [this.nativeName]);

  final String name;
  final String code;
  final String flag;
  final String? nativeName;
}

/// Shared country dialling data used by contact and account phone entry.
const docmacCountries = [
  ContactCountry('Nigeria', '+234', '🇳🇬'),
  ContactCountry('India', '+91', '🇮🇳'),
  ContactCountry('Pakistan', '+92', '🇵🇰', 'پاکستان'),
  ContactCountry('South Africa', '+27', '🇿🇦', 'iNingizimu Afrika'),
  ContactCountry('United Kingdom', '+44', '🇬🇧'),
  ContactCountry('United States', '+1', '🇺🇸'),
  ContactCountry('Afghanistan', '+93', '🇦🇫', 'افغانستان'),
  ContactCountry('Åland Islands', '+358', '🇦🇽', 'Åland'),
  ContactCountry('Albania', '+355', '🇦🇱', 'Shqipëri'),
  ContactCountry('Algeria', '+213', '🇩🇿', 'الجزائر'),
  ContactCountry('American Samoa', '+1', '🇦🇸'),
  ContactCountry('Andorra', '+376', '🇦🇩'),
  ContactCountry('Angola', '+244', '🇦🇴'),
  ContactCountry('Anguilla', '+1 264', '🇦🇮'),
  ContactCountry('Antigua and Barbuda', '+1 268', '🇦🇬'),
  ContactCountry('Argentina', '+54', '🇦🇷'),
  ContactCountry('Armenia', '+374', '🇦🇲'),
  ContactCountry('Aruba', '+297', '🇦🇼'),
  ContactCountry('Australia', '+61', '🇦🇺'),
  ContactCountry('Austria', '+43', '🇦🇹'),
  ContactCountry('Azerbaijan', '+994', '🇦🇿'),
  ContactCountry('Bahamas', '+1 242', '🇧🇸'),
  ContactCountry('Bahrain', '+973', '🇧🇭'),
  ContactCountry('Bangladesh', '+880', '🇧🇩'),
  ContactCountry('Barbados', '+1 246', '🇧🇧'),
  ContactCountry('Belarus', '+375', '🇧🇾'),
  ContactCountry('Belgium', '+32', '🇧🇪'),
  ContactCountry('Belize', '+501', '🇧🇿'),
  ContactCountry('Benin', '+229', '🇧🇯'),
  ContactCountry('Bermuda', '+1 441', '🇧🇲'),
  ContactCountry('Bhutan', '+975', '🇧🇹'),
  ContactCountry('Bolivia', '+591', '🇧🇴'),
  ContactCountry('Bosnia and Herzegovina', '+387', '🇧🇦'),
  ContactCountry('Botswana', '+267', '🇧🇼'),
  ContactCountry('Brazil', '+55', '🇧🇷'),
  ContactCountry('British Virgin Islands', '+1 284', '🇻🇬'),
  ContactCountry('Brunei', '+673', '🇧🇳'),
  ContactCountry('Bulgaria', '+359', '🇧🇬'),
  ContactCountry('Burkina Faso', '+226', '🇧🇫'),
  ContactCountry('Burundi', '+257', '🇧🇮'),
  ContactCountry('Cambodia', '+855', '🇰🇭'),
  ContactCountry('Cameroon', '+237', '🇨🇲'),
  ContactCountry('Canada', '+1', '🇨🇦'),
  ContactCountry('Cape Verde', '+238', '🇨🇻'),
  ContactCountry('Cayman Islands', '+1 345', '🇰🇾'),
  ContactCountry('Central African Republic', '+236', '🇨🇫'),
  ContactCountry('Chad', '+235', '🇹🇩'),
  ContactCountry('Chile', '+56', '🇨🇱'),
  ContactCountry('China', '+86', '🇨🇳'),
  ContactCountry('Colombia', '+57', '🇨🇴'),
  ContactCountry('Comoros', '+269', '🇰🇲'),
  ContactCountry('Congo', '+242', '🇨🇬'),
  ContactCountry('Costa Rica', '+506', '🇨🇷'),
  ContactCountry('Croatia', '+385', '🇭🇷'),
  ContactCountry('Cyprus', '+357', '🇨🇾'),
  ContactCountry('Czechia', '+420', '🇨🇿'),
  ContactCountry('Denmark', '+45', '🇩🇰'),
  ContactCountry('Dominica', '+1 767', '🇩🇲'),
  ContactCountry('Dominican Republic', '+1 809', '🇩🇴'),
  ContactCountry('Ecuador', '+593', '🇪🇨'),
  ContactCountry('Egypt', '+20', '🇪🇬'),
  ContactCountry('El Salvador', '+503', '🇸🇻'),
  ContactCountry('Estonia', '+372', '🇪🇪'),
  ContactCountry('Ethiopia', '+251', '🇪🇹'),
  ContactCountry('Finland', '+358', '🇫🇮'),
  ContactCountry('France', '+33', '🇫🇷'),
  ContactCountry('Gabon', '+241', '🇬🇦'),
  ContactCountry('Gambia', '+220', '🇬🇲'),
  ContactCountry('Georgia', '+995', '🇬🇪'),
  ContactCountry('Germany', '+49', '🇩🇪'),
  ContactCountry('Ghana', '+233', '🇬🇭'),
  ContactCountry('Greece', '+30', '🇬🇷'),
  ContactCountry('Grenada', '+1 473', '🇬🇩'),
  ContactCountry('Guam', '+1 671', '🇬🇺'),
  ContactCountry('Guatemala', '+502', '🇬🇹'),
  ContactCountry('Guinea', '+224', '🇬🇳'),
  ContactCountry('Guyana', '+592', '🇬🇾'),
  ContactCountry('Haiti', '+509', '🇭🇹'),
  ContactCountry('Hong Kong', '+852', '🇭🇰'),
  ContactCountry('Hungary', '+36', '🇭🇺'),
  ContactCountry('Iceland', '+354', '🇮🇸'),
  ContactCountry('Indonesia', '+62', '🇮🇩'),
  ContactCountry('Iran', '+98', '🇮🇷'),
  ContactCountry('Iraq', '+964', '🇮🇶'),
  ContactCountry('Ireland', '+353', '🇮🇪'),
  ContactCountry('Israel', '+972', '🇮🇱'),
  ContactCountry('Italy', '+39', '🇮🇹'),
  ContactCountry('Jamaica', '+1 876', '🇯🇲'),
  ContactCountry('Japan', '+81', '🇯🇵'),
  ContactCountry('Jordan', '+962', '🇯🇴'),
  ContactCountry('Kenya', '+254', '🇰🇪'),
  ContactCountry('Kuwait', '+965', '🇰🇼'),
  ContactCountry('Lebanon', '+961', '🇱🇧'),
  ContactCountry('Liberia', '+231', '🇱🇷'),
  ContactCountry('Libya', '+218', '🇱🇾'),
  ContactCountry('Luxembourg', '+352', '🇱🇺'),
  ContactCountry('Malaysia', '+60', '🇲🇾'),
  ContactCountry('Malta', '+356', '🇲🇹'),
  ContactCountry('Mauritius', '+230', '🇲🇺'),
  ContactCountry('Mexico', '+52', '🇲🇽'),
  ContactCountry('Morocco', '+212', '🇲🇦'),
  ContactCountry('Mozambique', '+258', '🇲🇿'),
  ContactCountry('Namibia', '+264', '🇳🇦'),
  ContactCountry('Nepal', '+977', '🇳🇵'),
  ContactCountry('Netherlands', '+31', '🇳🇱'),
  ContactCountry('New Zealand', '+64', '🇳🇿'),
  ContactCountry('Niger', '+227', '🇳🇪'),
  ContactCountry('Norway', '+47', '🇳🇴'),
  ContactCountry('Oman', '+968', '🇴🇲'),
  ContactCountry('Panama', '+507', '🇵🇦'),
  ContactCountry('Peru', '+51', '🇵🇪'),
  ContactCountry('Philippines', '+63', '🇵🇭'),
  ContactCountry('Poland', '+48', '🇵🇱'),
  ContactCountry('Portugal', '+351', '🇵🇹'),
  ContactCountry('Puerto Rico', '+1 787', '🇵🇷'),
  ContactCountry('Qatar', '+974', '🇶🇦'),
  ContactCountry('Romania', '+40', '🇷🇴'),
  ContactCountry('Rwanda', '+250', '🇷🇼'),
  ContactCountry('Saudi Arabia', '+966', '🇸🇦'),
  ContactCountry('Senegal', '+221', '🇸🇳'),
  ContactCountry('Serbia', '+381', '🇷🇸'),
  ContactCountry('Singapore', '+65', '🇸🇬'),
  ContactCountry('Slovakia', '+421', '🇸🇰'),
  ContactCountry('Slovenia', '+386', '🇸🇮'),
  ContactCountry('Somalia', '+252', '🇸🇴'),
  ContactCountry('South Korea', '+82', '🇰🇷'),
  ContactCountry('Spain', '+34', '🇪🇸'),
  ContactCountry('Sri Lanka', '+94', '🇱🇰'),
  ContactCountry('Sudan', '+249', '🇸🇩'),
  ContactCountry('Sweden', '+46', '🇸🇪'),
  ContactCountry('Switzerland', '+41', '🇨🇭'),
  ContactCountry('Taiwan', '+886', '🇹🇼'),
  ContactCountry('Tanzania', '+255', '🇹🇿'),
  ContactCountry('Thailand', '+66', '🇹🇭'),
  ContactCountry('Togo', '+228', '🇹🇬'),
  ContactCountry('Trinidad and Tobago', '+1 868', '🇹🇹'),
  ContactCountry('Tunisia', '+216', '🇹🇳'),
  ContactCountry('Turkey', '+90', '🇹🇷'),
  ContactCountry('Uganda', '+256', '🇺🇬'),
  ContactCountry('Ukraine', '+380', '🇺🇦'),
  ContactCountry('United Arab Emirates', '+971', '🇦🇪'),
  ContactCountry('Uruguay', '+598', '🇺🇾'),
  ContactCountry('Uzbekistan', '+998', '🇺🇿'),
  ContactCountry('Venezuela', '+58', '🇻🇪'),
  ContactCountry('Vietnam', '+84', '🇻🇳'),
  ContactCountry('Yemen', '+967', '🇾🇪'),
  ContactCountry('Zambia', '+260', '🇿🇲'),
  ContactCountry('Zimbabwe', '+263', '🇿🇼'),
];

const _contacts = [
  ('Amara Okafor', 'A', 'Available'),
  ('David Mensah', 'D', 'Design circle'),
  ('Nora Williams', 'N', 'Wave back to begin a conversation'),
  ('Tobi Adeyemi', 'T', 'Available'),
  ('Emma Clarke', 'E', 'Sent you a new moment'),
  ('Jack Wilson', 'J', 'Active now'),
];

class NewTalkPage extends StatefulWidget {
  const NewTalkPage({super.key});

  @override
  State<NewTalkPage> createState() => _NewTalkPageState();
}

class _NewTalkPageState extends State<NewTalkPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final matches = _contacts
        .where((contact) =>
            contact.$1.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('New talk'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Contact options',
            color: colors.surface,
            surfaceTintColor: Colors.transparent,
            onSelected: _handleMenu,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'broadcast', child: Text('New broadcast')),
              PopupMenuItem(value: 'settings', child: Text('Contact settings')),
              PopupMenuItem(value: 'invite', child: Text('Invite a contact')),
              PopupMenuItem(value: 'contacts', child: Text('People')),
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
              PopupMenuItem(value: 'help', child: Text('Help')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search name or number',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 18),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const _ActionAvatar(icon: DocmacIconlyLight.addUser),
            title: const Text('New circle'),
            subtitle: const Text('Bring people together in one talk'),
            onTap: () => context.push('/circle/new'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const _ActionAvatar(icon: Icons.person_add_alt_1_rounded),
            title: const Text('New contact'),
            subtitle: const Text('Save someone new to your Orbit'),
            onTap: () => context.push('/contacts/new'),
          ),
          const SizedBox(height: 18),
          Text('Frequently contacted',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          for (final contact in matches)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: colors.primary.withValues(alpha: .75),
                foregroundColor: colors.onPrimary,
                child: Text(contact.$2),
              ),
              title: Text(contact.$1),
              subtitle: Text(contact.$3),
              trailing: Icon(Icons.radio_button_unchecked_rounded,
                  color: colors.onSurfaceVariant),
              onTap: () => context.push('/chat'),
            ),
        ],
      ),
    );
  }

  void _handleMenu(String value) {
    switch (value) {
      case 'settings':
        context.push('/contacts/settings');
        return;
      case 'contacts':
        context.push('/contacts');
        return;
      case 'refresh':
        _notice('Your contacts are up to date.');
        return;
      case 'broadcast':
        _notice('New broadcast is ready to set up.');
        return;
      case 'invite':
        _notice('An invite link is ready to share.');
        return;
      case 'help':
        _notice('Choose a contact to start a private talk.');
        return;
    }
  }

  void _notice(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

class _ActionAvatar extends StatelessWidget {
  const _ActionAvatar({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: 25,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        child: Icon(icon),
      );
}

class ContactsDirectoryPage extends StatelessWidget {
  const ContactsDirectoryPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Contacts')),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            for (final contact in _contacts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text(contact.$2)),
                title: Text(contact.$1),
                subtitle: Text(contact.$3),
                onTap: () => context.push('/chat'),
              ),
          ],
        ),
      );
}

class ContactSettingsPage extends StatefulWidget {
  const ContactSettingsPage({super.key});

  @override
  State<ContactSettingsPage> createState() => _ContactSettingsPageState();
}

class _ContactSettingsPageState extends State<ContactSettingsPage> {
  bool _saveContacts = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Contacts')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Blocked accounts'),
              subtitle: const Text('6'),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Blocked accounts will appear here.')),
              ),
            ),
            const SizedBox(height: 36),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Orbit contacts'),
              subtitle: const Text(
                  'Contacts are saved to your Orbit account so they are available across your devices.'),
              value: _saveContacts,
              onChanged: (value) => setState(() => _saveContacts = value),
            ),
          ],
        ),
      );
}

class NewContactPage extends StatefulWidget {
  const NewContactPage({super.key});

  @override
  State<NewContactPage> createState() => _NewContactPageState();
}

class _NewContactPageState extends State<NewContactPage> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  ContactCountry _country = docmacCountries.first;
  bool _syncToPhone = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _chooseCountry() async {
    final country = await context.push<ContactCountry>('/contacts/country');
    if (country != null && mounted) setState(() => _country = country);
  }

  void _save() {
    if (_firstName.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a first name and phone number.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('${_firstName.text.trim()} has been added to contacts.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New contact')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
            child: Column(
              children: [
                TextField(
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'First name'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Last name'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: _chooseCountry,
                        child: Text('${_country.flag} ${_country.code}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.sync_rounded),
                  title: const Text('Sync contact to phone'),
                  value: _syncToPhone,
                  onChanged: (value) => setState(() => _syncToPhone = value),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: _save, child: const Text('Save contact')),
                ),
              ],
            ),
          ),
        ),
      );
}

class CountryPickerPage extends StatefulWidget {
  const CountryPickerPage({super.key});

  @override
  State<CountryPickerPage> createState() => _CountryPickerPageState();
}

class _CountryPickerPageState extends State<CountryPickerPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final countries = docmacCountries
        .where((country) {
          final query = _query.trim().toLowerCase();
          return query.isEmpty ||
              country.name.toLowerCase().contains(query) ||
              country.code.replaceAll(' ', '').contains(query);
        })
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 27),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Choose a country',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: scheme.onSurface,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.5,
                          ),
                    ),
                  ),
                  Icon(Icons.public_rounded, color: scheme.primary, size: 22),
                ],
              ),
            ),
            Container(height: 1, color: scheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search country or code',
                  prefixIcon: Icon(Icons.search_rounded,
                      color: scheme.onSurfaceVariant),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () => setState(() => _query = ''),
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: scheme.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 5, 24, 8),
              child: Row(
                children: [
                  Text(
                    _query.isEmpty
                        ? 'ALL COUNTRIES'
                        : '${countries.length} MATCH${countries.length == 1 ? '' : 'ES'}',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: countries.isEmpty
                  ? Center(
                      child: Text(
                        'No country found',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
                      itemCount: countries.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: scheme.outlineVariant),
                      itemBuilder: (context, index) {
                        final country = countries[index];
                        return InkWell(
                          onTap: () => context.pop(country),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 15),
                            child: Row(
                              children: [
                                Text(country.flag,
                                    style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        country.name,
                                        style: TextStyle(
                                          color: scheme.onSurface,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (country.nativeName != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          country.nativeName!,
                                          style: TextStyle(
                                              color: scheme.onSurfaceVariant,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  country.code,
                                  style: TextStyle(
                                    color: scheme.onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
