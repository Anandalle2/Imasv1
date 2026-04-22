import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { Activity, ShieldAlert, Navigation } from 'lucide-react-native';
import { COLORS, SIZES, UI_STYLES } from '../theme/theme';

export default function HomeScreen() {
  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <Text style={styles.title}>COMMAND CENTER</Text>
        <Text style={styles.subtitle}>System Status: ONLINE</Text>
      </View>

      <View style={styles.statsContainer}>
        <StatCard title="Active Vehicles" value="12" icon={<Navigation color={COLORS.primary} size={24} />} />
        <StatCard title="Alerts Today" value="3" icon={<ShieldAlert color={COLORS.warning} size={24} />} />
      </View>

      <View style={styles.moduleContainer}>
        <Text style={styles.sectionTitle}>ACTIVE MODULES</Text>
        
        <ModuleCard 
          title="Driver Monitoring" 
          status="Active" 
          statusColor={COLORS.success}
          icon={<Activity color={COLORS.success} size={32} />} 
        />
        
        <ModuleCard 
          title="Vehicle Detection" 
          status="Calibrating" 
          statusColor={COLORS.warning}
          icon={<ShieldAlert color={COLORS.warning} size={32} />} 
        />
      </View>
    </ScrollView>
  );
}

const StatCard = ({ title, value, icon }: any) => (
  <View style={styles.statCard}>
    <View style={styles.statHeader}>
      {icon}
      <Text style={styles.statValue}>{value}</Text>
    </View>
    <Text style={styles.statTitle}>{title}</Text>
  </View>
);

const ModuleCard = ({ title, status, statusColor, icon }: any) => (
  <View style={styles.moduleCard}>
    <View style={styles.moduleIconContainer}>
      {icon}
    </View>
    <View style={styles.moduleInfo}>
      <Text style={styles.moduleTitle}>{title}</Text>
      <View style={styles.statusBadge}>
        <View style={[styles.statusDot, { backgroundColor: statusColor }]} />
        <Text style={[styles.statusText, { color: statusColor }]}>{status}</Text>
      </View>
    </View>
  </View>
);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  content: {
    padding: SIZES.lg,
    paddingTop: SIZES.xxl,
  },
  header: {
    marginBottom: SIZES.xl,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: COLORS.primary,
    letterSpacing: 2,
  },
  subtitle: {
    fontSize: 14,
    color: COLORS.success,
    marginTop: 4,
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: SIZES.xl,
    gap: SIZES.md,
  },
  statCard: {
    ...UI_STYLES.glassmorphism,
    flex: 1,
    padding: SIZES.md,
  },
  statHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: SIZES.sm,
  },
  statValue: {
    fontSize: 24,
    fontWeight: 'bold',
    color: COLORS.text,
  },
  statTitle: {
    fontSize: 12,
    color: COLORS.textSecondary,
    textTransform: 'uppercase',
  },
  moduleContainer: {
    marginTop: SIZES.md,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: COLORS.textSecondary,
    marginBottom: SIZES.md,
    letterSpacing: 1,
  },
  moduleCard: {
    ...UI_STYLES.glassmorphism,
    flexDirection: 'row',
    padding: SIZES.md,
    marginBottom: SIZES.md,
    alignItems: 'center',
  },
  moduleIconContainer: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: 'rgba(255,255,255,0.05)',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: SIZES.md,
  },
  moduleInfo: {
    flex: 1,
  },
  moduleTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: COLORS.text,
    marginBottom: 4,
  },
  statusBadge: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 6,
  },
  statusText: {
    fontSize: 12,
    fontWeight: 'bold',
    textTransform: 'uppercase',
  },
});
