{{$.Importer.Import "models" (index $.OutputPackages "models") }}
{{ $table := .Table}}
{{ $tAlias := .Aliases.Table $table.Key -}}

// setModelRels creates and sets the relationships on *models.{{$tAlias.UpSingular}}
// according to the relationships in the template. Nothing is inserted into the db
func (t {{$tAlias.UpSingular}}Template) setModelRels(o *models.{{$tAlias.UpSingular}}) {
    {{- range $index, $rel := $.Relationships.Get $table.Key -}}
        {{- $relAlias := $tAlias.Relationship .Name -}}
        {{- $invRel := $.Relationships.GetInverse . -}}
        {{- $ftable := $.Aliases.Table $rel.Foreign -}}
        {{- $invAlias := "" -}}
    {{- if and (not $.NoBackReferencing) $invRel.Name -}}
            {{- $invAlias = $ftable.Relationship $invRel.Name}}
        {{- end -}}

        if t.r.{{$relAlias}} != nil {
            {{- if not .IsToMany}}
                rel := t.r.{{$relAlias}}.o.Build()
                {{- if and (not $.NoBackReferencing) $invRel.Name}}
                    {{- if not $invRel.IsToMany}}
                        rel.R.{{$invAlias}} = o
                    {{- else}}
                        rel.R.{{$invAlias}} = append(rel.R.{{$invAlias}}, o)
                    {{- end}}
                {{- end}}
                {{$.Tables.SetFactoryDeps $.CurrentPackage $.Importer $.Types $.Aliases . false}}
            {{- else -}}
                rel := models.{{$ftable.UpSingular}}Slice{}
                for _, r := range t.r.{{$relAlias}} {
                  related := r.o.BuildMany(r.number)
                  {{- $setter := $.Tables.SetFactoryDeps $.CurrentPackage $.Importer $.Types $.Aliases . false}}
                  {{- if or $setter (and (not $.NoBackReferencing) $invRel.Name) }}
                  for _, rel := range related {
                    {{$setter}}
                    {{- if and (not $.NoBackReferencing) $invRel.Name}}
                        {{- if not $invRel.IsToMany}}
                            rel.R.{{$invAlias}} = o
                        {{- else}}
                            rel.R.{{$invAlias}} = append(rel.R.{{$invAlias}}, o)
                        {{- end}}
                    {{- end}}
                  }
                  {{- end}}
                  rel = append(rel, related...)
                }
            {{- end}}
            o.R.{{$relAlias}} = rel
        }

    {{end -}}
}

{{if $table.Constraints.Primary -}}
// BuildSetter returns an *models.{{$tAlias.UpSingular}}Setter
// this does nothing with the relationship templates
func (o {{$tAlias.UpSingular}}Template) BuildSetter() *models.{{$tAlias.UpSingular}}Setter {
	m := &models.{{$tAlias.UpSingular}}Setter{}

	{{range $column := $table.Columns -}}
	{{- if $column.Generated}}{{continue}}{{end -}}
	{{$colAlias := $tAlias.Column $column.Name -}}
  {{$colGetter := $.Types.ToOptional $.CurrentPackage $.Importer $column.Type "val" $column.Nullable $column.Nullable -}}
		if o.{{$colAlias}} != nil {
      val := o.{{$colAlias}}()
      m.{{$colAlias}} = {{$colGetter}}
		}
	{{end}}

	return m
}

// BuildManySetter returns an []*models.{{$tAlias.UpSingular}}Setter
// this does nothing with the relationship templates
func (o {{$tAlias.UpSingular}}Template) BuildManySetter(number int) []*models.{{$tAlias.UpSingular}}Setter {
	m := make([]*models.{{$tAlias.UpSingular}}Setter, number)

	for i := range m {
	  m[i] = o.BuildSetter()
	}

	return m
}
{{- end}}

// Build returns an *models.{{$tAlias.UpSingular}}
// Related objects are also created and placed in the .R field
// NOTE: Objects are not inserted into the database. Use {{$tAlias.UpSingular}}Template.Create
func (o {{$tAlias.UpSingular}}Template) Build() *models.{{$tAlias.UpSingular}} {
  m := &models.{{$tAlias.UpSingular}}{}

  {{range $column := $table.Columns -}}
  {{$colAlias := $tAlias.Column $column.Name -}}
      if o.{{$colAlias}} != nil {
          m.{{$colAlias}} = o.{{$colAlias}}()
      }
  {{end}}

	o.setModelRels(m)

	return m
}

// BuildMany returns an models.{{$tAlias.UpSingular}}Slice
// Related objects are also created and placed in the .R field
// NOTE: Objects are not inserted into the database. Use {{$tAlias.UpSingular}}Template.CreateMany
func (o {{$tAlias.UpSingular}}Template) BuildMany(number int) models.{{$tAlias.UpSingular}}Slice {
	m := make(models.{{$tAlias.UpSingular}}Slice, number)

	for i := range m {
	  m[i] = o.Build()
	}

	return m
}
