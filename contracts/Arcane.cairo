%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import (
unsigned_div_rem, 
sqrt,
assert_lt)
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.cairo_keccak.keccak import keccak_felts, finalize_keccak
from starkware.cairo.common.cairo_builtins import (HashBuiltin, BitwiseBuiltin)
from starkware.starknet.common.syscalls import (get_contract_address, get_caller_address)
from openzeppelin.token.erc721.library import (
    ERC721_name,
    ERC721_symbol,
    ERC721_balanceOf,
    ERC721_ownerOf,
    ERC721_getApproved,
    ERC721_isApprovedForAll,

    ERC721_initializer,
    ERC721_approve, 
    ERC721_setApprovalForAll, 
    ERC721_transferFrom,
    ERC721_safeTransferFrom,
    ERC721_mint,
    ERC721_burn,
    ERC721_only_token_owner,
    ERC721_setTokenURI
)
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check, uint256_eq, uint256_unsigned_div_rem
)
from openzeppelin.access.ownable import (
    Ownable_initializer,
    Ownable_only_owner,
    Ownable_transfer_ownership
)
from openzeppelin.token.erc721.library import _exists
from openzeppelin.utils.ShortString import uint256_to_ss
from openzeppelin.utils.Array import concat_arr
from openzeppelin.utils.constants import TRUE, FALSE
from starkware.starknet.common.syscalls import (
    get_block_number,
    get_block_timestamp,
)

const MAX_STAR_SUPPLY = 1999
const MAX_ARCANE_SUPPLY = 5555
# TODO: check sending erc20
# const PRICE = 50000000000000000
const PRICE = 1000000000000000
const ETH_CONTRACT = 2087021424722619777119509474943472645767659996348769578120564519014510906823

# TODO: STUDY THIS
@view
func archetype(convoyable_type : felt) -> (movability : felt):
    let (data_address) = get_label_location(movabilities)
    return (cast(data_address, felt*)[convoyable_type])

    movabilities:
    dw 1 # "Wizard",
    dw 2 # "Mage",
    dw 3 # "Priest",
    dw 4 # "Warlock",
    dw 5 # "Mentah",
    dw 6 # "Sorcerer",
    dw 7 # "Druid",
    dw 8 # "Enchanter",
    dw 9 # "Astronomer",
    dw 10 # "Elementalist",
    dw 11 # "Shadowcaster"
end

@view
func affinities(convoyable_type : felt) -> (movability : felt):
    let (data_address) = get_label_location(movabilities)
    return (cast(data_address, felt*)[convoyable_type])

    movabilities:
    dw 1 # Arcane
    dw 2 # Shadow
    dw 3 # Divine
    dw 4 # Elemental
    dw 5 # Voodoo
    dw 6 # Wild
end

@view
func identities(convoyable_type : felt) -> (movability : felt):
    let (data_address) = get_label_location(movabilities)
    return (cast(data_address, felt*)[convoyable_type])

    movabilities:
    dw 1 # "Zen",
    dw 2 # "Uncivilized",
    dw 3 # "Adventurer",
    dw 4 # "Logistician",
    dw 5 # "Farsighted",
    dw 6 # "Mysterious",
    dw 7 # "Paranoiac",
    dw 8 # "Stoic",
    dw 9 # "Suspicious",
    dw 10 # "Honest",
    dw 11 # "Introvert",
    dw 12 # "Leader",
    dw 13 # "Quiet",
    dw 14 # "Inspired",
    dw 15 # "Curious",
    dw 16 # "Veteran",
    dw 17 # "Honest",
    dw 18 # "Fearless",
    dw 19 # "Calculated",
    dw 20 # "Applied",
    dw 21 # "Cunning",
    dw 22 # "Spiritual",
    dw 23 # "Tenacious",
    dw 24 # "Scarred",
    dw 25 # "Hermit",
    dw 26 # "Immoral",
    dw 27 # "Ruthless",
    dw 28 # "Primitive",
    dw 29 # "Brooding"
end

@view
func races(convoyable_type : felt) -> (movability : felt):
    let (data_address) = get_label_location(movabilities)
    return (cast(data_address, felt*)[convoyable_type])

    movabilities:
    dw 1 # Human
    dw 2 # Siam
    dw 3 # Undead
    dw 4 # Sylvan
    dw 5 # "Yord",
end

struct Wizard:
    member wizId : felt
    member wizName : felt
    member race : felt
    member class : felt
    member affinity : felt
    member character1 : felt
    member character2 : felt
    member mana : felt
    member birthday : felt
end

struct Skills:
    member focus :felt
    member strength : felt
    member intellect : felt
    member spell : felt
    member endurance : felt
end

@contract_interface
namespace IERC20:
    func transfer(recipient: felt, amount: Uint256) -> (success: felt):
    end
    func transferFrom(
            sender: felt,
            recipient: felt,
            amount: Uint256
        ) -> (success: felt):
    end
    func balanceOf(account: felt) -> (balance: Uint256):
    end
    func approve(spender: felt, amount: Uint256) -> (success: felt):
    end
end 

#TESTESTEST
@storage_var
func eth_temp ()-> (res : felt):
end

@storage_var
func get_base_skill( wiz_id : felt, skill_id : felt) -> ( res  : felt ):
end

@storage_var
func wiz_base_skills(wiz_id : felt) -> ( res : Skills):
end

@storage_var
func get_wizard ( wiz_id : felt ) -> ( res : Wizard ):
end

@storage_var
func curr_star_index() -> ( index : felt ):
end

@storage_var
func arcane_minted ( arcane_id : Uint256) -> ( res : felt ):
end

@storage_var
func ERC721_base_tokenURI(index: felt) -> (res: felt):
end

@storage_var
func ERC721_base_tokenURI_len() -> (res: felt):
end

@storage_var
func connected( address : felt ) -> ( res : felt ):
end

@storage_var
func vault ()->( res : felt):
end

@constructor
func constructor { syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr }( name : felt, symbol : felt ):
    ERC721_initializer(name, symbol)
    let (caller_address) = get_caller_address()
    Ownable_initializer(caller_address)
    return()
end

#
#   VIEW
#

@view
func get_wiz_infos { syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} ( wiz_id : felt)->( res : Wizard ):
    let (wiz_info_to_return ) = get_wizard.read(wiz_id) 
    return(wiz_info_to_return)
end

@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt) -> (
        balance : Uint256):
    let (balance : Uint256) = ERC721_balanceOf(owner)
    
    return (balance)
end

@view
func ownerOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (owner : felt):
    let (owner : felt) = ERC721_ownerOf(token_id)
    return (owner)
end


@view
func view_get_keccak_hash{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(salt : felt, value_to_hash : felt) -> (hashed_value : Uint256):
    alloc_locals
    let (local keccak_ptr_start) = alloc()
    let keccak_ptr = keccak_ptr_start
    # let (local keccak_ptr : felt*) = alloc()
    let (local arr : felt*) = alloc()
    assert arr[0] = salt
    assert arr[1] = value_to_hash
    let (hashed_value) = keccak_felts{keccak_ptr=keccak_ptr}(2, arr)
    finalize_keccak(keccak_ptr_start=keccak_ptr_start, keccak_ptr_end=keccak_ptr)
    return (hashed_value)
end

#
#   EXTERNAL
#

@external
func mint_arcane_mage { syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin* }( wiz_id : felt , wiz_name : felt ):
    alloc_locals
    # check for supply
    let (already_minted) = arcane_minted.read(Uint256(wiz_id,0))
     with_attr error_message("Ownable: caller is not the owner"):
        assert already_minted = FALSE
    end

    let (curr_index) =curr_star_index.read()
    let new_index = curr_index+1
    
    _mint_wiz(wiz_id,wiz_name)
    arcane_minted.write(Uint256(wiz_id,0), TRUE)
 
    return()
end

@external
func mint_star_mage { syscall_ptr : felt* , pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*  } ( wiz_name : felt ):
    alloc_locals
    # check supply
    let ( local curr_supply) = curr_star_index.read()
    with_attr error_message("All Star Wizards have been summoned"):
        assert_lt(curr_supply, MAX_STAR_SUPPLY)
    end
    # check payment
    let (this_address) = get_contract_address()
    let (caller_address) = get_caller_address()
    let (eth_address) = eth_temp.read()
    let (sucess) = IERC20.transferFrom(eth_address, caller_address ,this_address,Uint256(PRICE,0))

    let new_wiz_id = 5555+curr_supply+1
    _mint_wiz(new_wiz_id,wiz_name)
    curr_star_index.write(curr_supply+1)
    return()
end


func _mint_wiz { syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*  } ( wiz_id : felt, wiz_name : felt):
    alloc_locals
    # mint
    let (caller_address) = get_caller_address()
    local wiz_id = 0
    ERC721_mint(caller_address,Uint256(wiz_id,0))  

    # get random stats from 10 randoms
    let (local values : felt* ) = alloc()
    
    let (block_number) = get_block_number()
    let (block_timestamp) = get_block_timestamp()
    let (longhash) = view_get_keccak_hash(block_number,wiz_name)
    #make array of modulos
    let (local modulos : felt*) = alloc()

    assert [modulos] = 5
    assert [modulos+1] = 11
    assert [modulos+2] = 6
    assert [modulos+3] = 29
    assert [modulos+4] = 29
    assert [modulos+5] = 6
    assert [modulos+6] = 6
    assert [modulos+7] = 6
    assert [modulos+8] = 6
    assert [modulos+9] = 6
    let (_,rands_len,rands) = get_randoms(10,10,modulos,longhash,10, values)


    let (modulo_stat : Uint256,rem : Uint256) = uint256_unsigned_div_rem(longhash,Uint256(100,0))
    let (modulo_test : Uint256,rem_test : Uint256) = uint256_unsigned_div_rem(Uint256(99,0),Uint256(10,0)) 

    let new_race = rands[0]
    let new_class = rands[1]
    let new_affinity = rands[2]
    let new_char1 = rands[3]
    let new_char2 = rands[4]
    let new_focus = rands[5]
    let new_strength = rands[6]
    let new_intellect = rands[7]
    let new_spell = rands[8]
    let new_endurance = rands[9]

    let new_wizard = Wizard(wizId=wiz_id
        ,wizName=wiz_name
        ,race=new_race
        ,class=new_class
        ,affinity=new_affinity
        ,character1=new_char1
        ,character2=new_char2
        ,mana=240
        ,birthday=0)
    let new_skills = Skills(focus=new_focus
        ,strength=new_strength
        ,intellect=new_intellect
        ,spell=new_spell
        ,endurance=new_endurance)
    
    wiz_base_skills.write(wiz_id,new_skills)
    get_wizard.write(wiz_id,new_wizard)

    return()
end

func get_randoms{syscall_ptr:felt*,pedersen_ptr:HashBuiltin*,range_check_ptr}(
        start_len : felt
        ,modulos_len : felt
        ,modulos : felt*
        , curr_hash :Uint256
        , arr_len : felt
        , arr : felt*
    )->( res_hash :Uint256, res_len : felt , res : felt*):
    alloc_locals
    if arr_len==0:
        return(curr_hash, 0, arr)
    end
    local local_curr_hash : Uint256 = curr_hash
    # return if what's left on the hash is lower than 100
    assert_lt(100,local_curr_hash.low)

    let ( returned_hash, returned_len, returned_arr ) = get_randoms(start_len=start_len,modulos_len=modulos_len-1,modulos=modulos+1, curr_hash = local_curr_hash, arr_len = arr_len-1, arr= arr+1)
   
    let curr_modulo = [modulos]
    let ( new_hash, rand_uint : Uint256) = uint256_unsigned_div_rem(returned_hash, Uint256(curr_modulo,0))
    let rand_felt = rand_uint.low
    assert [arr] = rand_felt

    return (new_hash, arr_len, arr)
end

@external
func use_mana { syscall_ptr:felt*,pedersen_ptr:HashBuiltin*,range_check_ptr}(wiz_id :felt, amount : felt):
    let (caller_address) = get_caller_address()
    let (is_caller_connected) = connected.read(caller_address)
    with_attr error_message("Not authorized"):
        assert is_caller_connected=TRUE
    end

    let (wiz) = get_wizard.read(wiz_id)
    let curr_wiz_mana = wiz.mana
    let new_mana = curr_wiz_mana - amount
    # let is_highe
    return()
end

@external
func banish_wiz { syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr } (wiz_id : felt):
    let (caller) = get_caller_address()
    let (wiz_owner) = ownerOf(Uint256(wiz_id,0))
    with_attr error_message("You don't own this wizard"):
        assert caller = wiz_owner
    end

    ERC721_burn(Uint256(wiz_id,0))

    return()
end

@external
func whitelist_arcanes { syscall_ptr : felt*, pedersen_ptr: HashBuiltin*, range_check_ptr } ( wiz_arr_len : felt, wiz_arr : felt* ):
    Ownable_only_owner()
    if wiz_arr_len==0:
        return()
    end

    whitelist_arcanes(wiz_arr_len = wiz_arr_len-1, wiz_arr = wiz_arr+1)
    let wiz_id = Uint256([wiz_arr],0)
    arcane_minted.write(wiz_id, TRUE)

    return()
end


#
#   ERC721
#

@external
func approve{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        to : felt, token_id : Uint256):
    ERC721_approve(to, token_id)
    return ()
end

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        operator : felt, approved : felt):
    ERC721_setApprovalForAll(operator, approved)
    return ()
end

@external
func transferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        _from : felt, to : felt, token_id : Uint256):
    ERC721_transferFrom(_from, to, token_id)
    return ()
end

@external
func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        _from : felt, to : felt, token_id : Uint256, data_len : felt, data : felt*):
    ERC721_safeTransferFrom(_from, to, token_id, data_len, data)
    return ()
end

#
#   URI
#

@external
func ERC721_tokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(token_id: Uint256) -> (tokenURI_len: felt, tokenURI: felt*):
    alloc_locals

    let (exists) = _exists(token_id)
    assert exists = TRUE

    # Return tokenURI with an array of felts, `${base_tokenURI}/${token_id}`
    let (local base_tokenURI) = alloc()
    let (local base_tokenURI_len) = ERC721_base_tokenURI_len.read()
    _ERC721_baseTokenURI(base_tokenURI_len, base_tokenURI)
    let (token_id_ss_len, token_id_ss) = uint256_to_ss(token_id)
    let (tokenURI, tokenURI_len) = concat_arr(
        base_tokenURI_len,
        base_tokenURI,
        token_id_ss_len,
        token_id_ss,
    )

    return (tokenURI_len=tokenURI_len, tokenURI=tokenURI)
end


func _ERC721_baseTokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(base_tokenURI_len: felt, base_tokenURI: felt*):
    if base_tokenURI_len == 0:
        return ()
    end
    let (base) = ERC721_base_tokenURI.read(base_tokenURI_len)
    assert [base_tokenURI] = base
    _ERC721_baseTokenURI(base_tokenURI_len=base_tokenURI_len - 1, base_tokenURI=base_tokenURI + 1)
    return ()
end

@external
func ERC721_setBaseTokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(tokenURI_len: felt, tokenURI: felt*):
    Ownable_only_owner()
    _ERC721_setBaseTokenURI(tokenURI_len, tokenURI)
    ERC721_base_tokenURI_len.write(tokenURI_len)
    return ()
end


func _ERC721_setBaseTokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(tokenURI_len: felt, tokenURI: felt*):
    if tokenURI_len == 0:
        return ()
    end
    ERC721_base_tokenURI.write(index=tokenURI_len, value=[tokenURI])
    _ERC721_setBaseTokenURI(tokenURI_len=tokenURI_len - 1, tokenURI=tokenURI + 1)
    return ()
end

@external
func allowance_withdraw{syscall_ptr:felt*,pedersen_ptr:HashBuiltin*,range_check_ptr}(amount : felt):
    Ownable_only_owner()
    let (caller_address) = get_caller_address()
    let (eth_address) = eth_temp.read()
    IERC20.approve(eth_address,caller_address,Uint256(amount,0))
    return()
end

@external
func withdraw {syscall_ptr:felt*,pedersen_ptr:HashBuiltin*,range_check_ptr}():
    # send to vault
    Ownable_only_owner()
    let (this_address) = get_contract_address()
    let (caller_address) = get_caller_address()
    let (eth_address) = eth_temp.read()
    let (balance) = IERC20.balanceOf(eth_address,this_address)
    IERC20.transferFrom(eth_address,this_address,caller_address,balance)
    return()
end

@external
func set_vault{syscall_ptr:felt*,pedersen_ptr:HashBuiltin*,range_check_ptr}(address : felt ):
    Ownable_only_owner()
    vault.write(address)
    return()
end

@external
func set_eth{syscall_ptr: felt*,pedersen_ptr: HashBuiltin*,range_check_ptr}( address : felt):
    eth_temp.write(address)
    return()
end

@external
func transfer_ownership{syscall_ptr:felt*,pedersen_ptr:HashBuiltin*,range_check_ptr}(new_owner : felt ):
    Ownable_only_owner()
    Ownable_transfer_ownership(new_owner)
    return()
end
