# Event Invitation Materials Feature Design

## Overview

The Event Invitation Materials feature extends the existing event system to support uploading and displaying invitation materials in the form of photos (JPG, PNG) and PDF files. This feature is completely optional and independent of existing presentation videos, allowing event organizers to provide rich visual content for their events.

## Architecture

The feature integrates with the existing event management system by:

1. **Database Layer**: Adding new tables to store invitation material metadata
2. **Storage Layer**: Utilizing existing R2Storage infrastructure for file storage
3. **UI Layer**: Extending existing event forms and display pages
4. **Validation Layer**: Adding file type and size validation

## Components and Interfaces

### Database Schema

**New Table: `event_invitation_materials`**

```sql
CREATE TABLE event_invitation_materials (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  filename VARCHAR(255) NOT NULL,
  original_filename VARCHAR(255) NOT NULL,
  file_type VARCHAR(10) NOT NULL, -- 'jpg', 'png', 'pdf'
  file_size BIGINT NOT NULL,
  r2_key VARCHAR(500) NOT NULL,
  uploaded_at TIMESTAMP NOT NULL DEFAULT NOW(),
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_event_invitation_materials_event_id ON event_invitation_materials(event_id);
```

### Elixir Modules

**Schema Module: `Sahajyog.Events.EventInvitationMaterial`**

- Ecto schema for invitation materials
- Changeset validation for file metadata
- File type and size validation

**Context Updates: `Sahajyog.Events`**

- `create_invitation_material/2` - Create new material record
- `list_invitation_materials/1` - Get materials for an event
- `delete_invitation_material/1` - Remove material and R2 file
- `delete_event_materials/1` - Cleanup all materials for an event

**File Upload Handler**

- Integration with existing R2Storage module
- File path generation: `Events/{slug}/invitations/{uuid}-{filename}`
- MIME type validation and file extension checking

## Data Models

### EventInvitationMaterial Schema

```elixir
defmodule Sahajyog.Events.EventInvitationMaterial do
  use Ecto.Schema
  import Ecto.Changeset

  schema "event_invitation_materials" do
    field :filename, :string
    field :original_filename, :string
    field :file_type, :string
    field :file_size, :integer
    field :r2_key, :string
    field :uploaded_at, :utc_datetime

    belongs_to :event, Sahajyog.Events.Event

    timestamps()
  end

  @allowed_types ~w(jpg jpeg png pdf)
  @max_file_size 10_485_760 # 10MB

  def changeset(material, attrs) do
    material
    |> cast(attrs, [:filename, :original_filename, :file_type, :file_size, :r2_key, :event_id])
    |> validate_required([:filename, :original_filename, :file_type, :file_size, :r2_key, :event_id])
    |> validate_inclusion(:file_type, @allowed_types)
    |> validate_number(:file_size, greater_than: 0, less_than_or_equal_to: @max_file_size)
    |> foreign_key_constraint(:event_id)
  end
end
```

## Correctness Properties

_A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees._

### Property 1: File Type and Size Validation

_For any_ uploaded file, if it is accepted by the system, then it must be one of the allowed file types (JPG, PNG, PDF) and not exceed 10MB in size
**Validates: Requirements 1.2, 1.3**

### Property 2: R2 Storage Path Uniqueness and Format

_For any_ uploaded invitation material, the R2 storage key must follow the pattern `Events/{event_slug}/invitations/{uuid}-{sanitized_filename}` and be unique across all uploads
**Validates: Requirements 1.4, 4.2**

### Property 3: Multiple File Upload Independence

_For any_ event, multiple invitation materials can be uploaded simultaneously and each material can be independently deleted without affecting other materials
**Validates: Requirements 2.1, 2.3, 2.5**

### Property 4: Complete Material Cleanup

_For any_ invitation material that is deleted, both the database record and the R2 storage file must be removed completely
**Validates: Requirements 2.4**

### Property 5: Event Cascade Deletion

_For any_ event that is deleted, all associated invitation materials must be automatically removed from both database and R2 storage
**Validates: Requirements 4.1**

### Property 6: Event-Material Referential Integrity

_For any_ invitation material, it must be associated with exactly one valid event that exists in the system
**Validates: Requirements 4.5**

## Error Handling

### File Upload Errors

- **Invalid file type**: Clear message indicating allowed formats
- **File too large**: Specific message with size limit
- **Upload failure**: Retry mechanism with error logging
- **Storage failure**: Rollback database changes if R2 upload fails

### Display Errors

- **Missing files**: Graceful handling of broken R2 references
- **Corrupted files**: Error message instead of broken display
- **Network issues**: Fallback display with retry options

## Testing Strategy

### Unit Tests

- File validation logic
- R2 path generation
- Database operations (CRUD)
- Error handling scenarios

### Property-Based Tests

- File type validation across random inputs
- R2 path format consistency
- Event-material association integrity
- Cleanup operations completeness
- Multi-file management operations

### Integration Tests

- End-to-end file upload workflow
- Event deletion cascade behavior
- UI interaction with file management
- R2 storage integration

**Property-Based Testing Framework**: ExUnitProperties (Elixir's property testing library)
**Test Configuration**: Minimum 100 iterations per property test
**Test Tagging**: Each property test tagged with format: `# Feature: event-invitation-materials, Property {number}: {property_text}`

The testing strategy ensures both specific functionality (unit tests) and general correctness (property tests) are validated, providing comprehensive coverage for the invitation materials feature.
