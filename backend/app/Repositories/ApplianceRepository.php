<?php

namespace App\Repositories;

use App\Models\Appliance;
use Illuminate\Support\Collection;

class ApplianceRepository
{
    public function all(): Collection
    {
        return Appliance::orderBy('name')->get();
    }

    public function find(string $id): Appliance
    {
        return Appliance::findOrFail($id);
    }

    public function create(array $data): Appliance
    {
        return Appliance::create($data);
    }

    public function update(string $id, array $data): Appliance
    {
        $appliance = $this->find($id);
        $appliance->update($data);
        return $appliance->refresh();
    }

    public function delete(string $id): void
    {
        $this->find($id)->delete();
    }

    public function toggle(string $id): Appliance
    {
        $appliance = $this->find($id);
        $appliance->is_on = !$appliance->is_on;
        $appliance->save();
        return $appliance->refresh();
    }
}
