// "Skip other games": a page is left out when its name names another game (and not one we keep), or
// when one of its categories does and neither its name nor its categories name one we keep
// (shared entities like func_door stay; "Team Fortress 2/Grinders" goes though it is filed under Source).
// Phrases match whole words, any case: "Portal" catches "Prop portal", not "Func areaportal".
// Lists checked against a sample of 1414 real pages (21 November).
const VDC_SKIP_DEFAULT = [
  'Team Fortress', 'TF2', 'TFC', 'Left 4 Dead', 'L4D', 'L4D2', 'Portal', 'Counter-Strike', 'CS:GO', 'CSGO', 'CS2',
  'Alien Swarm', 'Source 2', 'Workshop Tools', 'GoldSrc', 'Xash3D', 'Dota', 'Alyx', 'Black Mesa',
  '=Half-Life', 'Half-Life 1', 'HL1', 'Half-Life Level Design', 'Half-Life: Source', 'Half-Life Deathmatch',
  'Opposing Force', 'Blue Shift', 'Ricochet', 'Deathmatch Classic', 'INFRA', 'The Ship', 'SiN Episodes', 'Vampire',
  'Bloodlines', 'Dark Messiah', 'Day of Defeat', 'Mapbase', 'Strata Source', 'Source Filmmaker', 'VScript', 'Squirrel',
  'Insurgency', 'Nuclear Dawn', 'Dino D-Day', 'Contagion', 'Zeno Clash', 'Deadlock', 'Underlords', 'Titanfall',
  'Synergy', 'Empires', 'Fistful of Frags', 'Postal', "XBLAH's Modding Tool",
].join('\n');
const VDC_KEEP_DEFAULT = [
  'Half-Life 2', 'HL2', 'Episode One', 'Episode Two', 'Episode 1', 'Episode 2', 'EP1', 'EP2', 'HL2EP1', 'HL2EP2',
  'Episodic', 'Lost Coast', "Garry's Mod", 'GMod', 'Source SDK 2013', 'Source 2013', '=Source',
].join('\n');
const VDC_FILTER_DEFAULTS = { skipOtherGames: true, skipWords: VDC_SKIP_DEFAULT, keepWords: VDC_KEEP_DEFAULT };

// Translated copies: "Func_door/de", and the older way, "Ko/Making a Mod".
const VDC_LANGS = new Set(('ar bg ca cs da de el eo es et fa fi fr he hi hr hu id it ja ka ko lt lv ms nl no ' +
  'pl pt pt-br pt-pt ro ru sk sl sr sv th tr uk vi zh zh-cn zh-hans zh-hant zh-hk zh-tw').split(' '));
function vdcIsTranslation(title) {
  const i = title.lastIndexOf('/');
  if (i < 0) return false;
  const name = title.slice(title.indexOf(':') + 1);
  return VDC_LANGS.has(title.slice(i + 1)) || VDC_LANGS.has(name.slice(0, name.indexOf('/')).toLowerCase());
}

// "=Name" matches a name or category that is exactly Name ("=Source" is Source 1 itself, not "Source 2").
function vdcMatchers(text) {
  const esc = (p) => p.toLowerCase().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return String(text || '').split('\n').map((s) => s.trim()).filter(Boolean).map((p) => (p.startsWith('=')
    ? new RegExp('^' + esc(p.slice(1).trim()) + '$')
    : new RegExp('(^|[^a-z0-9])' + esc(p) + '($|[^a-z0-9])')));
}

// A function (title, categories) -> true when the page should be left out; null when the filter is off.
function vdcJudge(settings) {
  if (!settings || !settings.skipOtherGames) return null;
  const skip = vdcMatchers(settings.skipWords);
  const keep = vdcMatchers(settings.keepWords);
  const any = (res, texts) => res.some((re) => texts.some((t) => re.test(t)));
  const norm = (t) => String(t).replace(/_/g, ' ').toLowerCase();
  return (title, cats) => {
    const name = [norm(title)];
    if (any(skip, name) && !any(keep, name)) return true;
    const texts = name.concat((cats || []).map(norm));
    return any(skip, texts) && !any(keep, texts);
  };
}
