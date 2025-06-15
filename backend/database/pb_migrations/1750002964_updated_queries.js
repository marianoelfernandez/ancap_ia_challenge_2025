/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_464205976")

  // remove field
  collection.fields.removeById("text3217214002")

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_464205976")

  // add field
  collection.fields.addAt(6, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text3217214002",
    "max": 0,
    "min": 0,
    "name": "consul",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  return app.save(collection)
})
