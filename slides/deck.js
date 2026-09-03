/*
 * G.A Design — slides の操作。
 *
 * 面の移動(← → ↑ ↓ SPACE、画面の左1/4より右をクリックで次へ)と、
 * 画面いっぱいへの拡大だけを持つ。成果物へはこのまま <script> に埋め込む。
 */
const slides = Array.from(document.querySelectorAll('.gad-slide'));
const viewport = document.querySelector('.gad-slides');
let at = 0;

/*
 * 面の番号は URL に置くが、履歴は積まない。
 * location.hash へ代入すると面を1つ動かすたびに履歴が1つ増え、戻るボタンが
 * 面ではなく URL だけを1つ戻す。デッキから出るのに、進めた枚数ぶん戻る羽目になる。
 */
const show = (next) => {
  at = Math.min(Math.max(next, 0), slides.length - 1);
  slides.forEach((slide, i) => slide.classList.toggle('is-current', i === at));
  history.replaceState(null, '', `#${at + 1}`);
};

/* 0.94 は面の周りに残す余白。 */
const fit = () => {
  const css = getComputedStyle(document.documentElement);
  const w = parseFloat(css.getPropertyValue('--gad-slide-w'));
  const h = parseFloat(css.getPropertyValue('--gad-slide-h'));
  const scale = Math.min(window.innerWidth / w, window.innerHeight / h) * 0.94;
  viewport.style.setProperty('--gad-slide-scale', scale);
};

document.addEventListener('keydown', (e) => {
  const step = { ArrowRight: 1, ArrowDown: 1, ' ': 1, ArrowLeft: -1, ArrowUp: -1 }[e.key];
  if (step === undefined) return;
  e.preventDefault();
  show(at + step);
});

/* 文字を選んだときと、link を押したときは面を動かさない。読み手が面を触れなくなるので。 */
document.addEventListener('click', (e) => {
  if (e.target instanceof Element && e.target.closest('a')) return;
  if (window.getSelection().toString()) return;
  show(at + (e.clientX < window.innerWidth / 4 ? -1 : 1));
});
window.addEventListener('resize', fit);
window.addEventListener('hashchange', () => show(Number(location.hash.slice(1)) - 1 || 0));
show(Number(location.hash.slice(1)) - 1 || 0);
fit();
