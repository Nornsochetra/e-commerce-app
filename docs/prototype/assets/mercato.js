/* Mercato prototype — shared runtime for every screen file (plain JavaScript, no JSX, works from file://).
   1. Data: mock catalog + localStorage-backed cart, wishlist, orders, notifications, profile → window.Mercato
   2. Navigation: Mercato.to.* builds links to the screen files, Mercato.go / Mercato.goBack move between them
   3. Shared UI: Icon, ScreenLayout (header + floating tab bar + dock), cards, sheets, form fields … → globals
   Each screen HTML file loads React, ReactDOM, Babel and Tailwind from a CDN, then this file, then its own
   <script type="text/babel"> with the screen component. Nothing here talks to a real backend. */
(function () {
  const h = React.createElement, Fragment = React.Fragment;

  /* ---------- storage ---------- */
  const KEYS = { cart: 'mercato_cart', wishlist: 'mercato_wishlist', notifications: 'mercato_notifications', orders: 'mercato_orders', user: 'mercato_user', session: 'mercato_session' };
  const load = (key, fallback) => { try { const v = localStorage.getItem(key); return v === null ? fallback : JSON.parse(v); } catch (e) { return fallback; } };
  const save = (key, value) => { try { localStorage.setItem(key, JSON.stringify(value)); } catch (e) {} window.dispatchEvent(new Event('mercato-change')); };
  const resetAll = () => { Object.values(KEYS).forEach(k => { try { localStorage.removeItem(k); } catch (e) {} }); try { sessionStorage.removeItem('mercato_splash'); } catch (e) {} };

  /* ---------- catalog (mock) ---------- */
  const img = id => 'https://images.unsplash.com/photo-' + id + '?auto=format&fit=crop&w=800&q=80';
  const categories = [
    { id: 'a0000000-0000-4000-8000-000000000001', name: 'Accessories', slug: 'accessories', icon: 'watch' },
    { id: 'a0000000-0000-4000-8000-000000000002', name: 'Footwear', slug: 'footwear', icon: 'shoe' },
    { id: 'a0000000-0000-4000-8000-000000000003', name: 'Bags', slug: 'bags', icon: 'backpack' },
    { id: 'a0000000-0000-4000-8000-000000000004', name: 'Electronics', slug: 'electronics', icon: 'headphones' }
  ];
  const cat = name => { const c = categories.find(x => x.name === name); return { id: c.id, name: c.name }; };
  const usd = amount => ({ amount: Number(amount).toFixed(2), currency: 'USD' });
  const products = [
    { id: '11111111-1111-4111-8111-111111111111', name: 'Minimal Watch', description: 'A quiet, refined watch designed for everyday wear.', category: cat('Accessories'), price: usd(89), availableQuantity: 8, rating: '4.8', imageUrl: img('1523275335684-37898b6baf30'), badges: ['NEW', 'PREMIUM_PICK'], featured: true },
    { id: '22222222-2222-4222-8222-222222222222', name: 'Cloud Sneakers', description: null, category: cat('Footwear'), price: usd(74), availableQuantity: 12, rating: '4.6', imageUrl: img('1542291026-7eec264c27ff'), badges: ['BESTSELLER'], featured: true },
    { id: '33333333-3333-4333-8333-333333333333', name: 'Canvas Backpack', description: 'Durable canvas storage with a comfortable everyday silhouette.', category: cat('Bags'), price: usd(58), availableQuantity: 5, rating: '4.7', imageUrl: img('1553062407-98eeb64c6a62'), badges: ['BESTSELLER'], featured: true },
    { id: '44444444-4444-4444-8444-444444444444', name: 'Studio Headphones', description: 'Immersive sound with a lightweight over-ear design.', category: cat('Electronics'), price: usd(129), availableQuantity: 0, rating: '4.9', imageUrl: img('1505740420928-5e560c06d30e'), badges: ['PREMIUM_PICK'], featured: false },
    { id: '55555555-5555-4555-8555-555555555555', name: 'Classic Sunglasses', description: null, category: cat('Accessories'), price: usd(42), availableQuantity: 16, rating: '4.5', imageUrl: img('1511499767150-a48a237f0083'), badges: [], featured: false },
    { id: '66666666-6666-4666-8666-666666666666', name: 'Everyday Camera', description: 'A compact camera for documenting the moments that matter.', category: cat('Electronics'), price: usd(245), availableQuantity: 3, rating: '4.7', imageUrl: img('1516035069371-29a1b244cc32'), badges: ['NEW'], featured: true }
  ];
  const productById = id => products.find(p => String(p.id) === String(id));

  /* ---------- formatting ---------- */
  const money = (v, currency) => {
    const amount = v && typeof v === 'object' ? v.amount : v;
    const cur = (v && v.currency) || currency || 'USD';
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: cur }).format(Number(amount));
  };
  const label = s => String(s || '').replaceAll('_', ' ').toLowerCase().replace(/\b\w/g, c => c.toUpperCase());
  const fmtDate = iso => new Date(iso).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  const relTime = iso => {
    const diff = Date.now() - new Date(iso).getTime(), min = Math.floor(diff / 60000);
    if (min < 1) return 'Just now';
    if (min < 60) return min + ' min ago';
    const hr = Math.floor(min / 60);
    if (hr < 24) return hr + (hr === 1 ? ' hour ago' : ' hours ago');
    const day = Math.floor(hr / 24);
    if (day === 1) return 'Yesterday';
    if (day < 7) return day + ' days ago';
    return fmtDate(iso);
  };
  const ago = ms => new Date(Date.now() - ms).toISOString();
  const H = 3600000, D = 86400000;
  const initials = name => String(name || '?').trim().split(/\s+/).map(p => p[0]).slice(0, 2).join('').toUpperCase();
  const emailOk = v => /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(String(v || '').trim());
  const placeholder = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='600' height='600'%3E%3Crect width='600' height='600' fill='%23ECFDF5'/%3E%3Cg fill='none' stroke='%2310B981' stroke-width='10' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='210' y='230' width='180' height='140' rx='22'/%3E%3Cpath d='M255 230v-20a45 45 0 0 1 90 0v20'/%3E%3C/g%3E%3C/svg%3E";

  /* ---------- cart ---------- */
  const lineOf = (unit, qty) => ({ amount: (Number(unit.amount) * qty).toFixed(2), currency: unit.currency });
  const toCartItem = (p, quantity) => ({ id: 'cart-' + p.id, product: { id: p.id, name: p.name, imageUrl: p.imageUrl, availableQuantity: p.availableQuantity, category: p.category && p.category.name }, quantity, unitPrice: p.price, lineTotal: lineOf(p.price, quantity) });
  const buildCart = items => ({ id: 'c0000000-0000-4000-8000-000000000001', items, subtotal: usd(items.reduce((s, i) => s + Number(i.unitPrice.amount) * i.quantity, 0)), itemCount: items.reduce((s, i) => s + i.quantity, 0), updatedAt: new Date().toISOString() });
  const demoCart = () => buildCart([toCartItem(products[0], 1), toCartItem(products[2], 2)]);
  const normalizeCart = value => {
    if (Array.isArray(value)) { // legacy array shape from older prototype versions
      return buildCart(value.map((old, i) => { const p = productById(old.id) || products[i % products.length]; return toCartItem(p, old.cartQty || old.quantity || 1); }));
    }
    return value && Array.isArray(value.items) ? value : demoCart();
  };
  const getCart = () => normalizeCart(load(KEYS.cart, null));
  const saveCart = items => { const cart = buildCart(items); save(KEYS.cart, cart); return cart; };
  const clearCart = () => saveCart([]);
  /** Adds a product; resolves quantity against stock. Returns 'added' | 'updated' | 'max' | 'oos'. */
  const addToCart = (p, qty = 1) => {
    if (!p.availableQuantity) return 'oos';
    const cart = getCart(), found = cart.items.find(i => i.product.id === p.id);
    if (found && found.quantity >= p.availableQuantity) return 'max';
    const items = found
      ? cart.items.map(i => { if (i.product.id !== p.id) return i; const q = Math.min(i.quantity + qty, p.availableQuantity); return { ...i, quantity: q, lineTotal: lineOf(i.unitPrice, q) }; })
      : [...cart.items, toCartItem(p, Math.min(qty, p.availableQuantity))];
    saveCart(items);
    return found ? 'updated' : 'added';
  };
  const cartCount = () => getCart().itemCount;

  /* ---------- wishlist ---------- */
  const normalizeProduct = (item, i) => {
    if (item && item.price && item.price.amount) return productById(item.id) || item;
    return productById(item.id) || { id: String(item.id || i), name: item.name, category: typeof item.category === 'object' ? item.category : { id: 'legacy-' + i, name: item.category || 'Uncategorized' }, price: usd(Number(item.price || 0)), availableQuantity: item.stock ?? item.availableQuantity ?? 0, rating: String(item.rating || ''), imageUrl: item.image || item.imageUrl, badges: item.badges || [], featured: !!item.featured };
  };
  const getWishlist = () => { const v = load(KEYS.wishlist, null); return Array.isArray(v) ? v.map(normalizeProduct) : [products[1], products[4]]; };
  const saveWishlist = items => save(KEYS.wishlist, items);
  const inWishlist = id => getWishlist().some(p => p.id === id);
  const toggleWishlist = p => { const list = getWishlist(), has = list.some(x => x.id === p.id); saveWishlist(has ? list.filter(x => x.id !== p.id) : [...list, p]); return !has; };

  /* ---------- notifications ---------- */
  const defaultNotifications = () => [
    { id: 'a1111111-1111-4111-8111-111111111111', type: 'order', title: 'Your order is on the way', message: 'Order #MC-19842 has shipped and is moving toward Phnom Penh.', readAt: null, createdAt: ago(2 * H) },
    { id: 'b2222222-2222-4222-8222-222222222222', type: 'offer', title: 'A little something for you', message: 'Enjoy free standard delivery on your next mock order.', readAt: null, createdAt: ago(5 * H) },
    { id: 'c3333333-3333-4333-8333-333333333333', type: 'stock', title: 'Back in stock', message: 'Cloud Sneakers from your wishlist are available again.', readAt: ago(D), createdAt: ago(D + 2 * H) },
    { id: 'd4444444-4444-4444-8444-444444444444', type: 'order', title: 'Order delivered', message: 'Order #MC-20481 was delivered. We hope you enjoy it.', readAt: ago(12 * D), createdAt: ago(12 * D + H) }
  ];
  const getNotifications = () => {
    const v = load(KEYS.notifications, null);
    if (!Array.isArray(v)) return defaultNotifications();
    return v.map(n => n.createdAt ? n : { ...n, type: n.type || 'order', readAt: n.read ? new Date().toISOString() : null, createdAt: new Date().toISOString() });
  };
  const saveNotifications = items => save(KEYS.notifications, items);
  const unreadCount = () => getNotifications().filter(n => !n.readAt).length;
  const pushNotification = n => saveNotifications([{ id: (crypto.randomUUID ? crypto.randomUUID() : String(Date.now())), readAt: null, createdAt: new Date().toISOString(), ...n }, ...getNotifications()]);

  /* ---------- orders ---------- */
  const demoDelivery = { recipientName: 'Alex Morgan', email: 'alex@example.com', address: '12 Riverside Street, Phnom Penh' };
  const orderItem = (p, quantity) => ({ productId: p.id, name: p.name, quantity, unitPrice: p.price, lineTotal: lineOf(p.price, quantity) });
  const defaultOrders = () => [
    { id: 'd1984200-0000-4000-8000-000000000002', reference: 'MC-19842', status: 'shipped', items: [orderItem(products[1], 1)], delivery: demoDelivery, deliveryMethod: 'standard', estimatedDelivery: '2–4 business days', paymentMethod: 'cash_on_delivery', subtotal: usd(74), deliveryFee: usd(4), total: usd(78), createdAt: ago(3 * D), updatedAt: ago(D) },
    { id: 'd2048100-0000-4000-8000-000000000001', reference: 'MC-20481', status: 'delivered', items: [orderItem(products[0], 1), orderItem(products[2], 2)], delivery: demoDelivery, deliveryMethod: 'standard', estimatedDelivery: 'Delivered', paymentMethod: 'cash_on_delivery', subtotal: usd(205), deliveryFee: usd(4), total: usd(209), createdAt: ago(14 * D), updatedAt: ago(11 * D) }
  ];
  const normalizeOrders = value => !Array.isArray(value) ? defaultOrders() : value.map((o, i) => o.reference ? o : { id: 'legacy-order-' + i, reference: String(o.id || 'MC-' + (19000 + i)), status: String(o.status || 'pending').toLowerCase(), items: [], delivery: demoDelivery, deliveryMethod: 'standard', estimatedDelivery: '2–4 business days', paymentMethod: 'cash_on_delivery', subtotal: usd(Number(o.total || 0)), deliveryFee: usd(0), total: usd(Number(o.total || 0)), createdAt: new Date(o.date || Date.now()).toISOString(), updatedAt: new Date(o.date || Date.now()).toISOString(), legacyItemCount: Number(o.items || 0) });
  const getOrders = () => normalizeOrders(load(KEYS.orders, null));
  const saveOrders = items => save(KEYS.orders, items);
  const orderItemCount = o => o.items.reduce((s, i) => s + i.quantity, 0) + (o.legacyItemCount || 0);
  const DELIVERY_FEE = usd(4);

  /* ---------- user / session ---------- */
  const defaultUser = () => ({ id: 'a1e00000-0000-4000-8000-000000000001', name: 'Alex Morgan', email: 'alex@example.com', phone: '+855 12 345 678', role: 'USER', memberSince: '2026-01-14T08:30:00Z', createdAt: '2026-01-14T08:30:00Z', updatedAt: '2026-08-18T10:30:00Z' });
  const getUser = () => ({ ...defaultUser(), ...load(KEYS.user, {}) });
  const saveUser = u => save(KEYS.user, u);
  const getSession = () => load(KEYS.session, null);
  const setSession = s => save(KEYS.session, s);

  /* ---------- navigation between screen files ---------- */
  const withQuery = (file, params) => {
    const qs = new URLSearchParams(Object.entries(params || {}).filter(([, v]) => v != null && v !== '')).toString();
    return file + (qs ? '?' + qs : '');
  };
  const to = {
    splash: 'splash.html', login: 'login.html', register: 'register.html', forgotPassword: 'forgot-password.html', screens: 'screens.html',
    home: 'home.html',
    shop: (category, extra) => withQuery('categories.html', { category: category && category !== 'all' ? category : null, ...extra }),
    product: id => withQuery('product.html', { id }),
    cart: 'cart.html', checkout: 'checkout.html',
    orderConfirmed: id => withQuery('order-confirmed.html', { id }),
    orders: 'orders.html', order: id => withQuery('order-detail.html', { id }),
    wishlist: 'wishlist.html', notifications: 'notifications.html', profile: 'profile.html'
  };
  /** Open another screen. { replace: true } keeps it out of the back history (e.g. after placing an order). */
  const go = (href, options) => { if (options && options.replace) location.replace(href); else location.href = href; };
  /** Previous screen, or `fallback` when this screen was opened directly. */
  const goBack = fallback => { if (history.length > 1) history.back(); else go(fallback || to.home); };
  /** URL query of the current screen, e.g. product.html?id=… → { id } */
  const query = Object.fromEntries(new URLSearchParams(location.search));
  const onPage = file => location.pathname.endsWith('/' + file) || location.pathname.endsWith(file);

  /* ---------- toasts ---------- */
  const toastBus = new EventTarget();
  const toast = (text, action) => toastBus.dispatchEvent(new CustomEvent('toast', { detail: { text, action } }));
  const addWithFeedback = (p, qty = 1) => {
    const r = addToCart(p, qty);
    if (r === 'oos') toast(p.name + ' is out of stock');
    else if (r === 'max') toast('Maximum stock already in your cart');
    else toast(r === 'added' ? 'Added to cart' : 'Cart quantity updated', onPage(to.cart) ? undefined : { label: 'View cart', onClick: () => go(to.cart) });
    return r;
  };
  const favoriteWithFeedback = p => { const on = toggleWishlist(p); toast(on ? 'Saved to wishlist' : 'Removed from wishlist'); return on; };

  const Mercato = {
    KEYS, load, save, resetAll, categories, products, productById, money, label, fmtDate, relTime, initials, emailOk, placeholder, DELIVERY_FEE, usd, lineOf,
    getCart, saveCart, clearCart, addToCart, cartCount, toCartItem, buildCart,
    getWishlist, saveWishlist, inWishlist, toggleWishlist,
    getNotifications, saveNotifications, unreadCount, pushNotification,
    getOrders, saveOrders, orderItemCount, demoDelivery,
    getUser, saveUser, getSession, setSession,
    to, go, goBack, query, toast, addWithFeedback, favoriteWithFeedback
  };

  /* ======================= Shared UI ======================= */

  const ICONS = {
    leaf: '<path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.5 19 2c1 2 2 4.2 2 8 0 5.5-4.8 10-10 10Z"/><path d="M2 21c0-3 1.9-5.5 6-7.5 3-1.5 5-3 7-5"/>',
    home: '<path d="M3 11.5 12 4l9 7.5"/><path d="M5 10v10h14V10"/><path d="M10 20v-6h4v6"/>',
    grid: '<rect x="3.5" y="3.5" width="7" height="7" rx="1.8"/><rect x="13.5" y="3.5" width="7" height="7" rx="1.8"/><rect x="3.5" y="13.5" width="7" height="7" rx="1.8"/><rect x="13.5" y="13.5" width="7" height="7" rx="1.8"/>',
    heart: '<path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 0 0 0-7.8Z"/>',
    bag: '<path d="M5 8h14l-1 13H6L5 8Z"/><path d="M9 10V6.5a3 3 0 0 1 6 0V10"/>',
    cart: '<circle cx="9" cy="20" r="1.4"/><circle cx="18" cy="20" r="1.4"/><path d="M2.5 3.5h3l2.4 11.2a1.5 1.5 0 0 0 1.5 1.2h8.2a1.5 1.5 0 0 0 1.5-1.1L21 8H6.2"/>',
    box: '<path d="M21 8 12 3 3 8v8l9 5 9-5V8Z"/><path d="m3 8 9 5 9-5"/><path d="M12 13v8"/>',
    user: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
    bell: '<path d="M18 8a6 6 0 0 0-12 0c0 7-3 8-3 9h18c0-1-3-2-3-9"/><path d="M10 21h4"/>',
    search: '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
    eye: '<path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>',
    eyeoff: '<path d="M9.9 5.2A9.7 9.7 0 0 1 12 5c6.4 0 10 7 10 7a17 17 0 0 1-3.2 4"/><path d="M6.6 6.6A16.6 16.6 0 0 0 2 12s3.6 7 10 7a9.8 9.8 0 0 0 5.4-1.6"/><path d="m3 3 18 18"/><path d="M10 10a3 3 0 0 0 4 4"/>',
    back: '<path d="M19 12H5"/><path d="m12 19-7-7 7-7"/>',
    chevron: '<path d="m9 6 6 6-6 6"/>',
    chevronl: '<path d="m15 6-6 6 6 6"/>',
    google: '<path d="M21 12.2c0-.7-.1-1.3-.2-1.9H12v3.6h5a4.3 4.3 0 0 1-1.9 2.8v2.3h3c1.7-1.6 2.9-4 2.9-6.8Z" fill="#4285F4" stroke="none"/><path d="M12 21c2.5 0 4.6-.8 6.1-2.2l-3-2.3c-.8.6-1.8.9-3.1.9a5.4 5.4 0 0 1-5.1-3.7H3.8v2.4A9 9 0 0 0 12 21Z" fill="#34A853" stroke="none"/><path d="M6.9 13.7a5.4 5.4 0 0 1 0-3.4V7.9H3.8a9 9 0 0 0 0 8.2l3.1-2.4Z" fill="#FBBC05" stroke="none"/><path d="M12 6.6c1.4 0 2.6.5 3.6 1.4l2.7-2.7A9 9 0 0 0 3.8 7.9l3.1 2.4A5.4 5.4 0 0 1 12 6.6Z" fill="#EA4335" stroke="none"/>',
    apple: '<path d="M16.4 12.6c0-2.3 1.9-3.4 2-3.5a4.3 4.3 0 0 0-3.4-1.8c-1.4-.2-2.8.9-3.5.9s-1.8-.8-3-.8a4.5 4.5 0 0 0-3.8 2.3c-1.6 2.8-.4 7 1.2 9.3.8 1.1 1.700 2.400 2.900 2.300 1.200 0 1.600-.7 3-.7s1.800.7 3 .7 2-1.100 2.800-2.200a9.400 9.400 0 0 0 1.200-2.500 3.900 3.900 0 0 1-2.400-3.500ZM14.100 5.800A4 4 0 0 0 15 3a4.100 4.100 0 0 0-2.700 1.400 3.800 3.800 0 0 0-1 2.700 3.400 3.400 0 0 0 2.800-1.300Z" fill="currentColor" stroke="none"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    minus: '<path d="M5 12h14"/>',
    x: '<path d="M18 6 6 18M6 6l12 12"/>',
    check: '<path d="m5 12.5 4.5 4.5L19 7.5"/>',
    trash: '<path d="M3 6h18"/><path d="M8 6V4h8v2"/><path d="m6 6 1 14h10l1-14"/><path d="M10 11v5M14 11v5"/>',
    sliders: '<path d="M4 6h10M18 6h2M4 12h2M10 12h10M4 18h12M20 18h0"/><circle cx="16" cy="6" r="2"/><circle cx="8" cy="12" r="2"/><circle cx="18" cy="18" r="2"/>',
    star: '<path d="m12 3 2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9L12 3Z"/>',
    truck: '<path d="M2 6h11v10H2z"/><path d="M13 9h5l3 3v4h-8"/><circle cx="6.5" cy="17.5" r="1.8"/><circle cx="17.5" cy="17.5" r="1.8"/>',
    shield: '<path d="M12 3 4.5 6v6c0 4.5 3.2 7.8 7.5 9 4.3-1.2 7.5-4.5 7.5-9V6L12 3Z"/><path d="m9 12 2.2 2.2L15.5 10"/>',
    cash: '<rect x="2.5" y="6" width="19" height="12" rx="2.5"/><circle cx="12" cy="12" r="2.6"/><path d="M6 9.5v.01M18 14.5v.01"/>',
    card: '<rect x="2.5" y="5" width="19" height="14" rx="2.5"/><path d="M2.5 10h19"/><path d="M6 15h4"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    tag: '<path d="M3 12.2V4a1 1 0 0 1 1-1h8.2a1 1 0 0 1 .7.3l8 8a1 1 0 0 1 0 1.4l-7.2 7.2a1 1 0 0 1-1.4 0l-8-8a1 1 0 0 1-.3-.7Z"/><circle cx="8" cy="8" r="1.4"/>',
    alert: '<path d="M12 3 2 20h20L12 3Z"/><path d="M12 10v4M12 17v.01"/>',
    info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8v.01"/>',
    mail: '<rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="m3.5 7 8.5 6 8.5-6"/>',
    lock: '<rect x="5" y="10.5" width="14" height="10" rx="2.5"/><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5"/>',
    logout: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5"/><path d="M21 12H9"/>',
    edit: '<path d="M4 20h4L19 9l-4-4L4 16v4Z"/><path d="m13.5 6.5 4 4"/>',
    settings: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1Z"/>',
    help: '<circle cx="12" cy="12" r="9"/><path d="M9.5 9.5a2.6 2.6 0 1 1 3.7 2.4c-.8.4-1.2 1-1.2 1.8"/><path d="M12 17v.01"/>',
    phone: '<path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2Z"/>',
    pin: '<path d="M12 21s7-6.2 7-11.5A7 7 0 0 0 5 9.5C5 14.8 12 21 12 21Z"/><circle cx="12" cy="9.5" r="2.5"/>',
    watch: '<circle cx="12" cy="12" r="5"/><path d="M9 7.2 9.8 3h4.4l.8 4.2M9 16.8 9.8 21h4.4l.8-4.2M12 9.8V12l1.6 1"/>',
    shoe: '<path d="M2.5 17.5V13l4.3-1.2 2.7 2.2h4.3l5 1.6c1.7.6 2.7 1.3 2.7 2.7v.2H2.5Z"/><path d="M6.8 11.8V8M10 10v-2.5"/>',
    backpack: '<path d="M8.5 6.5a3.5 3.5 0 0 1 7 0"/><rect x="5" y="6.5" width="14" height="14.5" rx="3.5"/><path d="M9 14h6M9 18h6"/>',
    headphones: '<path d="M4 15v-3a8 8 0 0 1 16 0v3"/><rect x="3" y="14" width="5" height="7" rx="2"/><rect x="16" y="14" width="5" height="7" rx="2"/>',
    refresh: '<path d="M20 11a8 8 0 0 0-14.5-4"/><path d="M4 4v4h4"/><path d="M4 13a8 8 0 0 0 14.5 4"/><path d="M20 20v-4h-4"/>',
    checkall: '<path d="m1.5 12.5 4.5 4.5L14.5 8.5"/><path d="m11 16 1 1 9-9"/>',
    sparkle: '<path d="m12 3 1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8L12 3Z"/>'
  };
  /** Stroke icon on a 24px grid: <Icon name="cart" size={20} fill /> */
  function Icon({ name, size = 20, fill, strokeWidth = 1.8, className }) {
    return h('svg', { width: size, height: size, viewBox: '0 0 24 24', fill: fill ? 'currentColor' : 'none', stroke: 'currentColor', strokeWidth, strokeLinecap: 'round', strokeLinejoin: 'round', 'aria-hidden': 'true', focusable: 'false', className, dangerouslySetInnerHTML: { __html: ICONS[name] || '' } });
  }

  /* ---------- hooks ---------- */
  const reduceMotion = () => !!(window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches);
  /** Re-render when any Mercato data changes (this page or another tab). */
  function useStoreTick() {
    const [, setTick] = React.useState(0);
    React.useEffect(() => {
      const bump = () => setTick(n => n + 1);
      window.addEventListener('mercato-change', bump);
      window.addEventListener('storage', bump);
      return () => { window.removeEventListener('mercato-change', bump); window.removeEventListener('storage', bump); };
    }, []);
  }
  /** Short skeleton delay so loading states are visible in the prototype (skipped for reduced motion). */
  function useLoading(ms = 350) {
    const [loading, setLoading] = React.useState(!reduceMotion() && ms > 0);
    React.useEffect(() => { if (!loading) return; const t = setTimeout(() => setLoading(false), ms); return () => clearTimeout(t); }, []);
    return loading;
  }

  /* ---------- toast host ---------- */
  function ToastHost({ position }) {
    const [items, setItems] = React.useState([]);
    React.useEffect(() => {
      const onToast = e => {
        const id = Math.random(), item = { id, ...e.detail };
        setItems(list => [...list.slice(-1), item]);
        setTimeout(() => setItems(list => list.filter(t => t.id !== id)), item.action ? 5000 : 2600);
      };
      toastBus.addEventListener('toast', onToast);
      return () => toastBus.removeEventListener('toast', onToast);
    }, []);
    const dismiss = id => setItems(list => list.filter(t => t.id !== id));
    return h('div', { className: 'toast-host' + (position ? ' ' + position : ''), role: 'status', 'aria-live': 'polite' }, items.map(t =>
      h('div', { key: t.id, className: 'toast' },
        h('span', { className: 't-icon' }, h(Icon, { name: 'check', size: 14, strokeWidth: 3 })),
        h('span', { className: 't-text' }, t.text),
        t.action && h('button', { className: 't-action', onClick: () => { t.action.onClick(); dismiss(t.id); } }, t.action.label))));
  }

  /* ---------- app chrome ---------- */
  const TAB_ITEMS = [
    ['home', 'Home', to.home, 'home'],
    ['shop', 'Categories', to.shop(), 'grid'],
    ['wishlist', 'Wishlist', to.wishlist, 'heart'],
    ['cart', 'Cart', to.cart, 'bag'],
    ['profile', 'Profile', to.profile, 'user']
  ];
  /** Floating pill tab bar; `active` is one of home | shop | wishlist | cart | profile. */
  function TabBar({ active }) {
    const cart = cartCount();
    return h('nav', { className: 'tabbar', 'aria-label': 'Primary' }, TAB_ITEMS.map(([id, text, href, icon]) => {
      const on = active === id;
      return h('a', { key: id, href, 'aria-current': on ? 'page' : undefined, 'aria-label': text + (id === 'cart' && cart ? ', ' + cart + ' items' : '') },
        h(Icon, { name: icon, size: 22, fill: on && id === 'wishlist', strokeWidth: on ? 2 : 1.8 }),
        h('span', { className: 'label', 'aria-hidden': 'true' }, text),
        id === 'cart' && cart > 0 && h('span', { className: 'dot-badge', 'aria-hidden': 'true' }, cart > 99 ? '99+' : cart));
    }));
  }
  function BackButton({ onBack, label: text = 'Go back', className = 'circle-btn' }) {
    return h('button', { type: 'button', className, 'aria-label': text, onClick: onBack }, h(Icon, { name: 'chevronl', size: 22, strokeWidth: 2.2 }));
  }
  /** Native-style header: round back button (when onBack is given), centered title, optional end action. */
  function AppHeader({ title, sub, onBack, start, end }) {
    return h('header', { className: 'app-header' },
      h('div', { className: 'slot' }, start || (onBack && h(BackButton, { onBack }))),
      title ? h('h1', { className: 'title truncate' }, title, sub && h('small', null, sub)) : h('div'),
      h('div', { className: 'slot end' }, end));
  }
  function BellButton() {
    const unread = unreadCount();
    return h('a', { href: to.notifications, className: 'circle-btn', 'aria-label': 'Notifications' + (unread ? ', ' + unread + ' unread' : '') },
      h(Icon, { name: 'bell', size: 20 }), unread > 0 && h('span', { className: 'dot-badge' }, unread > 9 ? '9+' : unread));
  }
  function Brand({ href = to.home }) {
    return h('a', { href, className: 'brand', 'aria-label': 'Mercato home' }, h('span', { className: 'brand-mark' }, h(Icon, { name: 'leaf', size: 20, strokeWidth: 2 })), 'Mercato');
  }
  /**
   * Frame for every main screen. `header` sits sticky on top, `nav` toggles the floating tab bar (`active` = tab id),
   * `dock` is a floating primary-action bar (sits above the tab bar when both are shown).
   */
  function ScreenLayout({ active, header, nav = true, dock, bare, children }) {
    const toastPosition = dock && nav ? 'lifted' : dock ? 'over-dock' : nav ? '' : 'low';
    return h(Fragment, null,
      header,
      h('main', { id: 'main', tabIndex: -1, className: 'page' + (nav ? ' has-nav' : '') + (dock ? ' has-dock' : '') + (bare ? ' bare' : ''), style: { outline: 'none' } }, children),
      dock && h('div', { className: 'dock' + (nav ? ' above-nav' : '') }, dock),
      nav && h(TabBar, { active }),
      h(ToastHost, { position: toastPosition }));
  }
  /** Frame for sign-in, register and password screens (no tab bar). */
  function AuthLayout({ onBack, children }) {
    return h('main', { className: 'auth', style: { animation: 'fade-in .3s ease-out' } },
      h('div', { className: 'auth-top' },
        onBack ? h(BackButton, { onBack, label: 'Back to sign in' }) : h('span', { className: 'brand' }, h('span', { className: 'brand-mark' }, h(Icon, { name: 'leaf', size: 20, strokeWidth: 2 })), 'Mercato'),
        h('a', { href: to.screens, className: 'link muted', style: { fontSize: 13 } }, 'All screens')),
      children,
      h('p', { className: 'text-center t-meta mt-auto pt-8' }, 'Prototype only — please don’t enter real credentials.'),
      h(ToastHost, { position: 'low' }));
  }

  /* ---------- overlays & states ---------- */
  /** Modal bottom sheet with focus trap, Escape and backdrop dismissal. */
  function BottomSheet({ title, children, onClose, labelledBy = 'sheet-title', role = 'dialog' }) {
    const ref = React.useRef(null);
    const closeRef = React.useRef(onClose);
    closeRef.current = onClose; // Escape must use the latest handler (e.g. dirty-form checks)
    React.useEffect(() => {
      const prev = document.activeElement;
      const first = ref.current && ref.current.querySelector('input, select, textarea, button, a[href]');
      first && first.focus({ preventScroll: true });
      const onKey = e => {
        if (e.key === 'Escape') closeRef.current();
        if (e.key === 'Tab' && ref.current) {
          const f = [...ref.current.querySelectorAll('button:not(:disabled), input, select, textarea, a[href]')];
          if (!f.length) return;
          const a = f[0], z = f[f.length - 1];
          if (e.shiftKey && document.activeElement === a) { e.preventDefault(); z.focus(); }
          else if (!e.shiftKey && document.activeElement === z) { e.preventDefault(); a.focus(); }
        }
      };
      document.addEventListener('keydown', onKey);
      document.body.style.overflow = 'hidden';
      return () => { document.removeEventListener('keydown', onKey); document.body.style.overflow = ''; prev && prev.focus && prev.focus({ preventScroll: true }); };
    }, []);
    return h('div', { className: 'overlay', onMouseDown: e => { if (e.target === e.currentTarget) onClose(); } },
      h('div', { ref, className: 'sheet', role, 'aria-modal': 'true', 'aria-labelledby': labelledBy },
        h('div', { className: 'grab', 'aria-hidden': 'true' }),
        title && h('h2', { id: labelledBy, className: 'sheet-title' }, title), children));
  }
  function EmptyState({ icon = 'check', tone, title, text, action, secondary }) {
    return h('div', { className: 'empty' },
      h('div', { className: 'empty-icon' + (tone ? ' ' + tone : '') }, h(Icon, { name: icon, size: 36, strokeWidth: 1.7 })),
      h('h2', null, title), h('p', null, text), action, secondary);
  }
  function Spinner({ text }) { return h(Fragment, null, h('span', { className: 'spinner', 'aria-hidden': 'true' }), text); }
  function ProductGridSkeleton({ count = 4 }) {
    return h('div', { className: 'grid-2', 'aria-busy': 'true', 'aria-label': 'Loading products' }, Array.from({ length: count }, (_, i) =>
      h('div', { key: i, className: 'flex flex-col gap-2.5' }, h('div', { className: 'skeleton', style: { aspectRatio: '4/5', borderRadius: 20 } }), h('div', { className: 'skeleton', style: { height: 14, width: '75%' } }), h('div', { className: 'skeleton', style: { height: 12, width: '40%' } }))));
  }
  function ListSkeleton({ count = 3 }) {
    return h('div', { 'aria-busy': 'true', 'aria-label': 'Loading' }, Array.from({ length: count }, (_, i) =>
      h('div', { key: i, className: 'lcard' }, h('div', { className: 'skeleton', style: { width: 96, height: 112, borderRadius: 16 } }),
        h('div', { className: 'flex-1 pt-2' }, h('div', { className: 'skeleton', style: { height: 12, width: '40%' } }), h('div', { className: 'skeleton mt-2', style: { height: 16, width: '75%' } }), h('div', { className: 'skeleton mt-8', style: { height: 16, width: '30%' } })))));
  }

  /* ---------- products ---------- */
  function ProductImage({ src, alt, className }) {
    return h('img', { src: src || placeholder, alt: alt || '', className, loading: 'lazy', onError: e => { e.currentTarget.onerror = null; e.currentTarget.src = placeholder; } });
  }
  const productTag = p => (p.badges && p.badges[0] ? label(p.badges[0]) : null);
  function FavButton({ product: p, favorite, onFavorite, className = 'circle-btn sm on-media' }) {
    return h('button', { type: 'button', className, 'aria-pressed': !!favorite, 'aria-label': (favorite ? 'Remove ' : 'Save ') + p.name + (favorite ? ' from wishlist' : ' to wishlist'), onClick: () => onFavorite(p) },
      h(Icon, { name: 'heart', size: 18, fill: favorite, strokeWidth: 2 }));
  }
  /** Grid card: tall image with Add + favourite actions, details below. */
  function ProductCard({ product: p, favorite, onFavorite, onAdd }) {
    const tag = productTag(p), href = to.product(p.id);
    return h('article', { className: 'pcard' },
      h('div', { className: 'relative' },
        h('a', { href, className: 'pcard-media', 'aria-label': 'View ' + p.name }, h(ProductImage, { src: p.imageUrl, alt: p.name }), tag && h('span', { className: 'tag' }, tag)),
        h(FavButton, { product: p, favorite, onFavorite, className: 'circle-btn sm on-media pcard-fav' }),
        p.availableQuantity
          ? h('button', { type: 'button', className: 'pcard-add', 'aria-label': 'Add ' + p.name + ' to cart', onClick: () => onAdd(p) }, h(Icon, { name: 'plus', size: 16, strokeWidth: 2.6 }), 'Add')
          : h('span', { className: 'pcard-soldout' }, 'Sold out')),
      h('div', { className: 'pcard-info' },
        h('a', { href, className: 'pcard-name truncate' }, p.name),
        h('span', { className: 't-meta' }, p.category.name),
        h('div', { className: 'pcard-row' }, h('span', { className: 't-price' }, money(p.price)), h('span', { className: 'rating' }, h(Icon, { name: 'star', size: 13, fill: true }), p.rating || '–'))));
  }
  /** Horizontal card used by Wishlist and Home "New arrivals". */
  function ListCard({ product: p, favorite, onFavorite, onAdd }) {
    const tag = productTag(p), href = to.product(p.id);
    return h('article', { className: 'lcard' },
      h('a', { href, className: 'lcard-media', 'aria-label': 'View ' + p.name },
        h(ProductImage, { src: p.imageUrl, alt: p.name }),
        !p.availableQuantity && h('span', { className: 'pcard-soldout', style: { left: 6, bottom: 6, height: 24, fontSize: 11, padding: '0 8px' } }, 'Sold out')),
      h('div', { className: 'lcard-body' },
        h('div', { className: 'flex items-start justify-between gap-2' },
          h('div', { className: 'min-w-0' },
            h('p', { className: 't-meta' }, p.category.name + (tag ? ' · ' + tag : '')),
            h('a', { href, className: 't-head truncate block mt-0.5' }, p.name),
            h('span', { className: 'rating mt-1' }, h(Icon, { name: 'star', size: 12, fill: true }), p.rating || '–')),
          h(FavButton, { product: p, favorite, onFavorite, className: 'circle-btn sm' })),
        h('div', { className: 'lcard-foot' },
          h('span', { className: 't-price' }, money(p.price)),
          h('button', { type: 'button', className: 'circle-btn sm solid', disabled: !p.availableQuantity, style: !p.availableQuantity ? { opacity: .35 } : undefined, 'aria-label': 'Add ' + p.name + ' to cart', onClick: () => onAdd(p) }, h(Icon, { name: 'cart', size: 18 })))));
  }
  /** − value + control; `max` is the available stock. */
  function QtyStepper({ value, max, onChange, name, size }) {
    const of = name ? ' of ' + name : '';
    return h('div', { className: 'qty' + (size === 'lg' ? ' lg' : ''), role: 'group', 'aria-label': 'Quantity' + of },
      h('button', { type: 'button', 'aria-label': 'Decrease quantity' + of, disabled: value <= 1, onClick: () => onChange(value - 1) }, h(Icon, { name: 'minus', size: 16, strokeWidth: 2.4 })),
      h('output', { 'aria-live': 'polite' }, value),
      h('button', { type: 'button', 'aria-label': 'Increase quantity' + of, disabled: value >= max, onClick: () => onChange(value + 1) }, h(Icon, { name: 'plus', size: 16, strokeWidth: 2.4 })));
  }

  /* ---------- forms ---------- */
  /** Label + any control + inline error. */
  function FieldShell({ id, label: text, error, hint, children }) {
    return h('div', { className: 'field' },
      h('label', { className: 'field-label', htmlFor: id }, text), children,
      error ? h('p', { id: id + '-err', className: 'field-error', role: 'alert' }, h(Icon, { name: 'alert', size: 14 }), error)
        : hint && h('p', { id: id + '-hint', className: 'field-hint' }, hint));
  }
  /** Text input with label, inline validation and an optional show/hide password toggle. */
  function TextField({ id, label: text, error, hint, type = 'text', value, onChange, onBlur, toggle, children, ...rest }) {
    const [show, setShow] = React.useState(false);
    const isPw = type === 'password' && toggle;
    return h(FieldShell, { id, label: text, error, hint },
      h('div', { className: 'input-wrap' },
        h('input', { id, className: 'input', type: isPw && show ? 'text' : type, value, onChange: e => onChange(e.target.value), onBlur, 'aria-invalid': error ? 'true' : 'false', 'aria-describedby': error ? id + '-err' : hint ? id + '-hint' : undefined, ...rest }),
        isPw && h('button', { type: 'button', className: 'trail', 'aria-label': show ? 'Hide password' : 'Show password', 'aria-pressed': show, onClick: () => setShow(s => !s) }, h(Icon, { name: show ? 'eyeoff' : 'eye' }))),
      children);
  }
  /** Form state: values, touched-gated errors, and helpers to reveal and focus the first error. */
  function useForm(initial, validate) {
    const [values, setValues] = React.useState(initial);
    const [touched, setTouched] = React.useState({});
    const errors = validate(values);
    return {
      values, errors, valid: Object.keys(errors).length === 0,
      set: key => value => setValues(v => ({ ...v, [key]: value })),
      blur: key => () => setTouched(t => ({ ...t, [key]: true })),
      shown: key => (touched[key] ? errors[key] : undefined),
      touchAll: () => setTouched(Object.fromEntries(Object.keys(initial).map(k => [k, true]))),
      focusFirstError: () => setTimeout(() => { const el = document.querySelector('[aria-invalid="true"]'); el && el.focus(); }, 30)
    };
  }
  const RULES = {
    email: v => !v.trim() ? 'Enter your email address.' : !emailOk(v) ? 'Enter a valid email, like you@example.com.' : undefined,
    phone: v => v && !/^[+\d][\d\s()-]{5,}$/.test(v.trim()) ? 'Enter a valid phone number, or leave it blank.' : undefined
  };

  /* ---------- orders ---------- */
  const ORDER_STAGES = [
    ['pending', 'Order placed', 'We received your order'],
    ['confirmed', 'Confirmed', 'Your order is being prepared'],
    ['shipped', 'Shipped', 'On its way with our courier'],
    ['delivered', 'Delivered', 'Handed over to you']
  ];
  const ORDER_TONE = { pending: 'warning', confirmed: 'info', shipped: 'info', delivered: 'success' };
  function OrderStatusBadge({ status }) { return h('span', { className: 'badge ' + (ORDER_TONE[status] || 'neutral') }, label(status)); }
  const orderItemImage = item => (productById(item.productId) || {}).imageUrl;
  /** Standard delivery window: 2–4 days after the order was placed. */
  const deliveryWindow = iso => { const day = d => d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }), s = new Date(iso); return day(new Date(s.getTime() + 2 * 864e5)) + ' – ' + day(new Date(s.getTime() + 4 * 864e5)); };
  const paymentLabel = method => (method === 'cash_on_delivery' ? 'Cash on delivery' : label(method));

  /* ---------- mounting ---------- */
  /**
   * Render a screen into #root. The wrapper re-renders the whole screen whenever Mercato data changes
   * (cart, wishlist, …) and passes the shared navigation props:
   *   params/query — this page's URL query, e.g. product.html?id=… → { id }
   *   navigate(href, { replace }) — open another screen file
   *   goBack(fallbackHref) — previous screen, or the fallback when opened directly
   */
  function mount(Screen) {
    function Root() { useStoreTick(); return h(Screen, { params: query, query, navigate: go, goBack }); }
    ReactDOM.createRoot(document.getElementById('root')).render(h(Root));
  }
  Mercato.mount = mount;

  /* ---------- expose to screen files ---------- */
  window.Mercato = Mercato;
  Object.assign(window, {
    Icon, useStoreTick, useLoading, reduceMotion, ToastHost, TabBar, BackButton, AppHeader, BellButton, Brand, ScreenLayout, AuthLayout,
    BottomSheet, EmptyState, Spinner, ProductGridSkeleton, ListSkeleton, ProductImage, FavButton, ProductCard, ListCard, QtyStepper,
    FieldShell, TextField, useForm, RULES, ORDER_STAGES, OrderStatusBadge, orderItemImage, deliveryWindow, paymentLabel
  });
})();
