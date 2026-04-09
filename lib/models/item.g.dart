// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemTypeAdapter extends TypeAdapter<ItemType> {
  @override
  final int typeId = 0;

  @override
  ItemType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ItemType.weapon;
      case 1:
        return ItemType.armor;
      case 2:
        return ItemType.accessory;
      case 3:
        return ItemType.consumable;
      case 4:
        return ItemType.miscellaneous;
      default:
        return ItemType.weapon;
    }
  }

  @override
  void write(BinaryWriter writer, ItemType obj) {
    switch (obj) {
      case ItemType.weapon:
        writer.writeByte(0);
        break;
      case ItemType.armor:
        writer.writeByte(1);
        break;
      case ItemType.accessory:
        writer.writeByte(2);
        break;
      case ItemType.consumable:
        writer.writeByte(3);
        break;
      case ItemType.miscellaneous:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DamageTypeAdapter extends TypeAdapter<DamageType> {
  @override
  final int typeId = 1;

  @override
  DamageType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DamageType.slashing;
      case 1:
        return DamageType.piercing;
      case 2:
        return DamageType.bludgeoning;
      case 3:
        return DamageType.fire;
      case 4:
        return DamageType.cold;
      case 5:
        return DamageType.lightning;
      case 6:
        return DamageType.poison;
      case 7:
        return DamageType.psychic;
      case 8:
        return DamageType.radiant;
      case 9:
        return DamageType.necrotic;
      case 10:
        return DamageType.force;
      default:
        return DamageType.slashing;
    }
  }

  @override
  void write(BinaryWriter writer, DamageType obj) {
    switch (obj) {
      case DamageType.slashing:
        writer.writeByte(0);
        break;
      case DamageType.piercing:
        writer.writeByte(1);
        break;
      case DamageType.bludgeoning:
        writer.writeByte(2);
        break;
      case DamageType.fire:
        writer.writeByte(3);
        break;
      case DamageType.cold:
        writer.writeByte(4);
        break;
      case DamageType.lightning:
        writer.writeByte(5);
        break;
      case DamageType.poison:
        writer.writeByte(6);
        break;
      case DamageType.psychic:
        writer.writeByte(7);
        break;
      case DamageType.radiant:
        writer.writeByte(8);
        break;
      case DamageType.necrotic:
        writer.writeByte(9);
        break;
      case DamageType.force:
        writer.writeByte(10);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DamageTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ArmorTypeAdapter extends TypeAdapter<ArmorType> {
  @override
  final int typeId = 2;

  @override
  ArmorType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ArmorType.light;
      case 1:
        return ArmorType.medium;
      case 2:
        return ArmorType.heavy;
      case 3:
        return ArmorType.shield;
      default:
        return ArmorType.light;
    }
  }

  @override
  void write(BinaryWriter writer, ArmorType obj) {
    switch (obj) {
      case ArmorType.light:
        writer.writeByte(0);
        break;
      case ArmorType.medium:
        writer.writeByte(1);
        break;
      case ArmorType.heavy:
        writer.writeByte(2);
        break;
      case ArmorType.shield:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArmorTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
