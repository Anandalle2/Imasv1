import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { ShieldAlert, Activity, Navigation } from 'lucide-react-native';
import { COLORS, SIZES, UI_STYLES } from '../theme/theme';

export default function WelcomeScreen({ navigation }: any) {
  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Welcome to IMAS</Text>
        <Text style={styles.subtitle}>Advanced Fleet Management & Safety</Text>
      </View>

      <View style={styles.featuresContainer}>
        <FeatureItem 
          icon={<Activity color={COLORS.primary} size={32} />}
          title="Driver Monitoring"
          description="Real-time fatigue and distraction detection"
        />
        <FeatureItem 
          icon={<ShieldAlert color={COLORS.warning} size={32} />}
          title="Collision Warning"
          description="Advanced vehicle ahead detection"
        />
        <FeatureItem 
          icon={<Navigation color={COLORS.accent} size={32} />}
          title="Fleet Tracking"
          description="Live GPS tracking and telemetry"
        />
      </View>

      <View style={styles.footer}>
        <TouchableOpacity 
          style={styles.primaryButton}
          onPress={() => navigation.navigate('Login')}
        >
          <Text style={styles.primaryButtonText}>Get Started</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const FeatureItem = ({ icon, title, description }: any) => (
  <View style={styles.featureItem}>
    <View style={styles.iconContainer}>
      {icon}
    </View>
    <View style={styles.featureText}>
      <Text style={styles.featureTitle}>{title}</Text>
      <Text style={styles.featureDesc}>{description}</Text>
    </View>
  </View>
);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
    padding: SIZES.lg,
  },
  header: {
    marginTop: SIZES.xxl * 2,
    marginBottom: SIZES.xl,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: COLORS.text,
    marginBottom: SIZES.sm,
  },
  subtitle: {
    fontSize: 16,
    color: COLORS.textSecondary,
  },
  featuresContainer: {
    flex: 1,
    justifyContent: 'center',
    gap: SIZES.lg,
  },
  featureItem: {
    ...UI_STYLES.glassmorphism,
    flexDirection: 'row',
    padding: SIZES.md,
    alignItems: 'center',
  },
  iconContainer: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: 'rgba(0, 240, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: SIZES.md,
    borderWidth: 1,
    borderColor: COLORS.glassBorder,
  },
  featureText: {
    flex: 1,
  },
  featureTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: COLORS.text,
    marginBottom: 4,
  },
  featureDesc: {
    fontSize: 14,
    color: COLORS.textSecondary,
  },
  footer: {
    marginBottom: SIZES.xxl,
  },
  primaryButton: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: COLORS.primary,
    padding: SIZES.md,
    borderRadius: SIZES.md,
    alignItems: 'center',
    ...UI_STYLES.glow,
  },
  primaryButtonText: {
    color: COLORS.primary,
    fontSize: 18,
    fontWeight: 'bold',
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
});
