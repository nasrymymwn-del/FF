# Fix resort_name to name field rename in ResortInsideIraq and ResortOutsideIraq
# Migration 0114 created them as 'resort_name' but models.py uses 'name'

from django.db import migrations

class Migration(migrations.Migration):
    dependencies = [
        ('properties', '0117_alter_brokerchannel_governorate_and_more'),
    ]

    operations = [
        migrations.RenameField(
            model_name='resortinsideiraq',
            old_name='resort_name',
            new_name='name',
        ),
        migrations.RenameField(
            model_name='resortoutsideiraq',
            old_name='resort_name',
            new_name='name',
        ),
    ]