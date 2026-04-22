export const COLORS = {
  background: '#0B0F19',
  surface: '#151A27',
  primary: '#00F0FF',
  secondary: '#7000FF',
  accent: '#00FF9D',
  text: '#FFFFFF',
  textSecondary: '#8A95A5',
  error: '#FF0055',
  success: '#00FF9D',
  warning: '#FFB800',
  glassBackground: 'rgba(21, 26, 39, 0.6)',
  glassBorder: 'rgba(0, 240, 255, 0.3)',
};

export const SIZES = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 40,
};

export const FONTS = {
  regular: 'System', // You can replace with custom fonts if added
  bold: 'System',
};

export const UI_STYLES = {
  glassmorphism: {
    backgroundColor: COLORS.glassBackground,
    borderColor: COLORS.glassBorder,
    borderWidth: 1,
    borderRadius: SIZES.md,
  },
  glow: {
    shadowColor: COLORS.primary,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.8,
    shadowRadius: 10,
    elevation: 10,
  }
};
